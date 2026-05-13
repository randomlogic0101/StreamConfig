;;; core-utils.el -*- lexical-binding: t; -*-

(defun my/reload-emacs-config ()
  "Reload Emacs configuration."
  (interactive)
  (load-file user-init-file)
  (message "Emacs config reloaded."))

(defun my/kill-all-buffers ()
  (interactive)
  (mapc #'kill-buffer
        (seq-filter
         (lambda (buf)
           (not (string-prefix-p " " (buffer-name buf))))
         (buffer-list))))

(global-set-key (kbd "C-c K") #'my/kill-all-buffers)

(defun my/set-env-variable (var value)
  (interactive
   (list (read-string "Variable: ")
         (read-string "Value: ")))
  (setenv var value)
  (message "Set %s=%s" var value))

(defun my/list-unsaved-buffers ()
  "List all unsaved (modified) buffers in a temporary buffer."
  (interactive)
  (let ((buffers (seq-filter #'buffer-modified-p (buffer-list))))
    (if buffers
        (with-current-buffer (get-buffer-create "*Unsaved Buffers*")
          (setq buffer-read-only nil)
          (erase-buffer)
          (insert "Unsaved buffers:\n\n")
          (dolist (buf buffers)
            (insert (format "%-30s  %s\n"
                            (buffer-name buf)
                            (or (buffer-file-name buf) "[no file]"))))
          (special-mode) ;; gives nice keybindings like q to quit
          (display-buffer (current-buffer)))
      (message "No unsaved buffers."))))

(defun my/percent-lines-to-values (beg end total)
  "Convert lines of percentages in region to values of TOTAL.
Each line should contain a number like 90, 80, etc."
  (interactive
   (list (region-beginning)
         (region-end)
         (read-number "Enter total: ")))

  (let ((lines (split-string (buffer-substring-no-properties beg end) "\n" t))
        (result '()))

    (dolist (line lines)
      (let* ((num (string-to-number (string-trim line)))
             (value (* (/ num 100.0) total))
             ;; format to 2 decimal places, then clean trailing .00
             (formatted
              (replace-regexp-in-string
               "\\.?0+$"
               ""
               (format "%.2f" value))))
        (push (format "%d%% = %s" num formatted) result)))

    (setq result (string-join (nreverse result) "\n"))

    (delete-region beg end)
    (insert result)))


(defun my/copy-and-clear-buffer ()
  "Copy entire buffer to clipboard.
If buffer is writable, erase it.
If buffer is read-only, mimic terminal clear by pushing content off screen."
  (interactive)
  (let ((content (buffer-substring-no-properties (point-min) (point-max))))
    ;; Copy to kill ring + clipboard
    (kill-new content)

    (if buffer-read-only
        ;; Terminal-style clear
        (progn
          (goto-char (point-max))
          (insert "\n\n") ;; create space to scroll
          (recenter 0)
          (message "Buffer copied; view cleared (read-only buffer)."))

      ;; Writable buffer: erase
      (let ((inhibit-read-only t))
        (erase-buffer)
        (message "Buffer copied and cleared.")))))

(use-package ispell
  :ensure nil  ;; ispell comes with Emacs, don't install
  :config
  ;; Set the spell checker program
  (setq ispell-program-name "aspell")
  
  ;; Set the dictionary
  ;; Think this will work on everything, but something seems wrong with nixos
  (setq ispell-dictionary "en_US")
  (setq ispell-default-dictionary "en_US")
  
  ;; Personal dictionary location
  (setq ispell-personal-dictionary "~/.local/share/.ispell_words")
  
  ;; Handle NixOS/Nix package manager edge cases
  ;; Not sure if this is right yet.
  (when (file-exists-p "/nix/store")
    (setq ispell-dictionary "en")  ; NixOS often uses "en" instead of "en_US"
    (setq ispell-default-dictionary "en"))
  
  ;; Enable flyspell mode for text editing
  (require 'flyspell)
  (add-hook 'text-mode-hook #'flyspell-mode)
  (add-hook 'prog-mode-hook #'flyspell-prog-mode)
  
  ;(setq flyspell-auto-correct-when-moving t)
  ;(setq ispell-silently-ignore-case t)
  
  ;; Verify aspell is available
  ;; Think is will find it regardless of which of my systems im on
  (unless (executable-find "aspell")
    (message "Warning: aspell not found. Spell checking may not work.")))

(with-eval-after-load 'evil
  (define-key evil-visual-state-map (kbd "g p")
    #'my/percent-lines-to-values))

(defun my/set-default-directory-stream ()
  (interactive)
  (setq default-directory (expand-file-name "~/Stream/"))
  (message "default-directory set to %s" default-directory))

(global-set-key (kbd "C-c C-d s") #'my/set-default-directory-stream)
(global-set-key (kbd "C-c u") #'my/list-unsaved-buffers)
(global-set-key (kbd "C-c <backspace>") #'my/copy-and-clear-buffer)
(global-set-key (kbd "C-c E") #'my/set-env-variable)
(global-set-key (kbd "C-c r") #'my/reload-emacs-config)

(provide 'core-utils)
