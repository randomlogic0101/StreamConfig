;;; core-notes.el -*- lexical-binding: t; -*-

;; why not use org mode, all of these are built-in to emacs in org mode and you could use capture templates
(use-package markdown-mode)

(defun my/open-daily-note ()
  "Open today's daily note. Create it from the template if it doesn't exist.
   Uses $NOTESDIR if set, otherwise defaults to ~/Documents/Notes/.
   Adds a header to new files."
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

(global-set-key (kbd "C-c d") #'my/open-daily-note)

(provide 'core-notes)
