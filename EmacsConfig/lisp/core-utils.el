;;; core-utils.el -*- lexical-binding: t; -*-

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

(global-set-key (kbd "C-c E") #'my/set-env-variable)

(provide 'core-utils)
