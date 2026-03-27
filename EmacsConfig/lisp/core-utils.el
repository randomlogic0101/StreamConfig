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

(global-set-key (kbd "C-c <backspace>") #'my/copy-and-clear-buffer)
(global-set-key (kbd "C-c E") #'my/set-env-variable)
(global-set-key (kbd "C-c r") #'my/reload-emacs-config)

(provide 'core-utils)
