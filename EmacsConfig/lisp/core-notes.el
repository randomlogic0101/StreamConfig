;;; core-notes.el -*- lexical-binding: t; -*-

;; why not use org mode, all of these are built-in to emacs in org mode and you could use capture templates
(use-package markdown-mode)
(require 'cl-lib)

;; -------------------------
;; Config
;; -------------------------

(defvar my/stale-days 5
  "Number of days before a task is considered stale.")

(defvar my/lookback-days 10
  "How many past daily notes to scan.")

;; -------------------------
;; Helpers
;; -------------------------

(defun my/get-past-daily-files (notes-dir days)
  (let ((files '()))
    (dotimes (i days)
      (let* ((date (time-subtract (current-time) (days-to-time (1+ i))))
             (filename (format "dailyNote%s.md"
                               (format-time-string "%Y%m%d" date)))
             (filepath (expand-file-name filename notes-dir)))
        (when (file-exists-p filepath)
          (push (cons filepath (1+ i)) files))))
    files))

;; -------------------------
;; Task extraction
;; -------------------------

(defun my/extract-task-block ()
  "Extract a parent task and all of its children."
  (let ((indent (current-indentation))
        (block ""))
    (while (and (not (eobp))
                (or (= (current-indentation) indent)
                    (> (current-indentation) indent)))
      (setq block
            (concat block
                    (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))
                    "\n"))
      (forward-line 1))
    (string-trim-right block)))

(defun my/clean-task-block (block)
  "Remove completed child tasks from BLOCK."
  (let ((lines (split-string block "\n"))
        (result '()))
    (dolist (line lines)
      (unless (string-match-p "^[[:space:]]*- \\[[xX]\\]" line)
        (push line result)))
    (string-join (nreverse result) "\n")))

(defun my/extract-incomplete-tasks (filepath age)
  "Extract incomplete parent tasks and their children."
  (with-temp-buffer
    (insert-file-contents filepath)
    (let ((current-section nil)
          (result '()))
      (goto-char (point-min))

      (while (not (eobp))
        (cond
         ;; Section header
         ((looking-at "^## \\(.*\\)")
          (setq current-section (match-string 1))
          (forward-line 1))

         ;; Incomplete parent task ONLY (top-level)
         ((and current-section
               (looking-at "^- \\[ \\] ")
               (= (current-indentation) 0))
          (let* ((raw (my/extract-task-block))
                 (clean (my/clean-task-block raw)))
            (push (cons current-section
                        (list :task clean :age age :file filepath))
                  result)))

         ;; Skip completed OR already carried-forward tasks
         ((looking-at "^- \\[[xX>]\\] ")
          (forward-line 1))

         (t
          (forward-line 1))))

      result)))

(defun my/collect-tasks-from-past (notes-dir)
  (let ((files (my/get-past-daily-files notes-dir my/lookback-days))
        (all '()))
    (dolist (f files)
      (setq all (append all
                        (my/extract-incomplete-tasks (car f) (cdr f)))))
    all))

;; -------------------------
;; Deduplication
;; -------------------------

(defun my/task-key (task-block)
  "Use normalized first line as dedupe key."
  (string-trim (car (split-string task-block "\n"))))

(defun my/dedupe-tasks (tasks)
  (let ((table (make-hash-table :test 'equal))
        result)
    (dolist (entry tasks)
      (let* ((plist (cdr entry))
             (task (plist-get plist :task))
             (key (my/task-key task))
             (age (plist-get plist :age))
             (existing (gethash key table)))
        ;; Keep the NEWEST version (smallest age)
        (when (or (null existing)
                  (< age (plist-get (cdr existing) :age)))
          (puthash key entry table))))
    (maphash (lambda (_ v) (push v result)) table)
    result))

;; -------------------------
;; Mark carried forward
;; -------------------------

(defun my/mark-task-carried-forward (filepath task-block)
  "Mark the original task as carried forward (- [>])."
  (with-temp-buffer
    (insert-file-contents filepath)
    (goto-char (point-min))

    (let ((key (regexp-quote (my/task-key task-block))))
      (when (re-search-forward (concat "^\\(- \\)\\[ \\] " key) nil t)
        (replace-match "\\1[>] ")))

    (write-region (point-min) (point-max) filepath)))

(defun my/mark-all-carried-forward (tasks)
  (dolist (entry tasks)
    (let* ((plist (cdr entry))
           (task (plist-get plist :task))
           (file (plist-get plist :file)))
      (my/mark-task-carried-forward file task))))

;; -------------------------
;; Insert
;; -------------------------

(defun my/section-exists-p (section)
  (save-excursion
    (goto-char (point-min))
    (re-search-forward (format "^## %s" (regexp-quote section)) nil t)))

(defun my/create-section-if-missing (section)
  (unless (my/section-exists-p section)
    (goto-char (point-max))
    (insert (format "\n## %s\n\n" section))))

(defun my/insert-tasks-into-section (section tasks)
  (my/create-section-if-missing section)

  (goto-char (point-min))
  (re-search-forward (format "^## %s" (regexp-quote section)))
  (forward-line 1)

  ;; Move to first blank line after section header
  (while (and (not (eobp))
              (not (looking-at "^\\s-*$")))
    (forward-line 1))

  ;; Insert tasks
  (dolist (entry tasks)
    (insert (plist-get (cdr entry) :task) "\n\n")))

;; -------------------------
;; Migration
;; -------------------------

(defun my/migrate-incomplete-tasks (notes-dir)
  (let* ((raw (my/collect-tasks-from-past notes-dir))
         (tasks (my/dedupe-tasks raw))
         (grouped (make-hash-table :test 'equal)))

    ;; Group by section or stale
    (dolist (entry tasks)
      (let* ((section (car entry))
             (plist (cdr entry))
             (age (plist-get plist :age))
             (target (if (> age my/stale-days)
                         "Stale Tasks"
                       section)))
        (puthash target
                 (cons entry (gethash target grouped))
                 grouped)))

    ;; Insert tasks
    (maphash
     (lambda (section items)
       (my/insert-tasks-into-section section items))
     grouped)

    ;; Mark originals
    (my/mark-all-carried-forward tasks)))

;; -------------------------
;; Daily note
;; -------------------------

(defun my/open-daily-note ()
  (interactive)
  (let* ((notes-dir (file-name-as-directory
                     (or (getenv "NOTESDIR")
                         "~/Documents/Notes/")))
         (template-file (expand-file-name "Templates/dailyNotes.md" notes-dir))
         (filename (format "dailyNote%s.md" (format-time-string "%Y%m%d")))
         (filepath (expand-file-name filename notes-dir)))

    ;; Ensure directory exists
    (unless (file-directory-p notes-dir)
      (make-directory notes-dir t))

    (if (file-exists-p filepath)
        (find-file filepath)

      ;; Create new file
      (find-file filepath)

      ;; Insert header first
      (insert (format "# Daily Note for %s\n\n"
                      (format-time-string "%b, %d %Y")))

      ;; Then insert template (if it exists)
      (when (file-exists-p template-file)
        (insert-file-contents template-file))

      (goto-char (point-min))
      (save-buffer))))

;; This section is a test for converting markdown comments to latex for annotating student work

(defun my/md--tokenize (text)
  "Split TEXT into (type . content) where type is 'math or 'text."
  (let ((pos 0)
        tokens)
    (while (string-match "\\$[^$]*\\$" text pos)
      (let ((start (match-beginning 0))
            (end (match-end 0)))
        (when (> start pos)
          (push (cons 'text (substring text pos start)) tokens))
        (push (cons 'math (substring text start end)) tokens)
        (setq pos end)))
    (when (< pos (length text))
      (push (cons 'text (substring text pos)) tokens))
    (nreverse tokens)))

(defun my/md--wrap-lines (tokens max-width)
  "Wrap TOKENS into lines of approx MAX-WIDTH, preserving math chunks."
  (let ((lines '())
        (current "")
        (len 0))

    (defun my--flush-line ()
      (when (> (length current) 0)
        (push current lines)
        (setq current "" len 0)))

    (defun my--add-word (word)
      (let ((wlen (length word)))
        (if (> (+ len wlen 1) max-width)
            (progn
              (my--flush-line)
              (setq current word
                    len wlen))
          (setq current (if (string-empty-p current)
                            word
                          (concat current " " word))
                len (+ len wlen 1)))))

    (dolist (tok tokens)
      (pcase (car tok)
        ('math (my--add-word (cdr tok)))
        ('text
         (dolist (word (split-string (cdr tok) "\\s+" t))
           (my--add-word word)))))

    (my--flush-line)
    (nreverse lines)))

;; ✅ NEW: safe formatter
(defun my/md--format-line (line)
  "Format a single line into valid LaTeX with proper text/math separation."
  (let ((pos 0)
        (result ""))

    (while (string-match "\\$\\([^$]+\\)\\$" line pos)
      (let ((start (match-beginning 0))
            (end (match-end 0))
            (math (match-string 1 line)))

        (when (> start pos)
          (setq result
                (concat result
                        (format "\\textbf{%s}"
                                (string-trim (substring line pos start))))))

        (setq result
              (concat result
                      (format " \\boldsymbol{%s} " math)))

        (setq pos end)))

    (when (< pos (length line))
      (setq result
            (concat result
                    (format "\\textbf{%s}"
                            (string-trim (substring line pos))))))

    result))

;; ✅ FIXED
(defun my/md-to-latex (text)
  "Convert markdown TEXT into valid LaTeX with ~60 char aligned lines."
  (let* ((tokens (my/md--tokenize text))
         (lines (my/md--wrap-lines tokens 60))
         (processed
          (mapconcat
           (lambda (line)
             (format "& %s \\\\"
                     (my/md--format-line line)))
           lines
           "\n")))
    (format "{\\Huge\n\\begin{aligned}\n%s\n\\end{aligned}\n}" processed)))

(defun my/md-region-to-latex-clipboard (beg end)
  "Convert selected markdown region to LaTeX and copy to clipboard."
  (interactive "r")
  (let* ((input (buffer-substring-no-properties beg end))
         (output (my/md-to-latex input)))
    (kill-new output)
    (message "Converted to LaTeX (~60 char lines) and copied!")))

(with-eval-after-load 'evil
  (define-key evil-visual-state-map (kbd "g l")
    #'my/md-region-to-latex-clipboard))

;; End md -> latex for comments test section

(defun my/markdown-convert-to-links (beg end)
  "Convert lines in region from 'desc <whitespace> url' to Markdown links."
  (interactive "r")
  (let ((text (buffer-substring-no-properties beg end)))
    (delete-region beg end)
    (insert
     (mapconcat
      (lambda (line)
        (if (string-match "^\\s-*\\(.+?\\)\\s-+\\(https?://[^[:space:]]+\\)\\s-*$" line)
            (format "[%s](%s)"
                    (match-string 1 line)
                    (match-string 2 line))
          line))
      (split-string text "\n")
      "\n"))))

(defun my/markdown-links-to-html-copy (beg end)
  "Convert Markdown links in region to HTML and copy to clipboard."
  (interactive "r")
  (let* ((text (buffer-substring-no-properties beg end))
         (converted
          (replace-regexp-in-string
           "\\[\\([^]]+\\)\\](\\([^)]*\\))"
           "<a href=\"\\2\">\\1</a><br />"
           text)))
    (kill-new converted)
    (message "HTML copied to clipboard!")))


;; -------------------------
;; Keybinding
;; -------------------------

(global-set-key (kbd "C-c d") #'my/open-daily-note)
(define-key global-map (kbd "C-c m l") #'my/markdown-convert-to-links)
(define-key global-map (kbd "C-c m h") #'my/markdown-links-to-html-copy)

(provide 'core-notes)
