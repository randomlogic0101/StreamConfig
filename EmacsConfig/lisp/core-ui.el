;;; core-ui.el --- UI configuration -*- lexical-binding: t; -*-

(use-package emacs
  :ensure nil
  :init
  (setq inhibit-startup-message t
        vc-follow-symlinks t
        indent-tabs-mode nil
        tab-width 2)
  (fset 'yes-or-no-p 'y-or-n-p)
  :config
  (save-place-mode 1)
  (electric-pair-mode 1)
  (global-display-line-numbers-mode 1)

  ;; Window resizing
  (defun my/shrink-window-horizontally ()
    "Shrink window width by 5 columns."
    (interactive)
    (shrink-window-horizontally 5))

  (defun my/enlarge-window-horizontally ()
    "Enlarge window width by 5 columns."
    (interactive)
    (enlarge-window-horizontally 5))

  (global-set-key (kbd "C-c <left>")  #'my/shrink-window-horizontally)
  (global-set-key (kbd "C-c <right>") #'my/enlarge-window-horizontally))

;; Relative line numbers
(defun my/relative-line-numbers ()
  (unless (or (minibufferp)
              (derived-mode-p 'special-mode))
    (setq display-line-numbers-type 'relative)))

(add-hook 'after-change-major-mode-hook #'my/relative-line-numbers)

;; Theme
(use-package doom-themes
  :config
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

;; Toggle menu/tool bars

(defun my/toggle-tool-and-menu-bars ()
  "Toggle the visibility of the tool‑bar and the menu‑bar.

If either the tool‑bar or the menu‑bar is currently shown, both are
hidden; otherwise both are shown.  The command also prints a short
message in the echo area so you know the new state."
  (interactive)
  (let* ((tool-visible   (frame-parameter nil 'tool-bar-lines))
         (menu-visible   (frame-parameter nil 'menu-bar-lines))
         (new-visibility (if (or (= tool-visible 1) (= menu-visible 1)) 0 1)))
    ;; Apply the same value to both parameters
    (modify-frame-parameters nil
                             `((tool-bar-lines . ,new-visibility)
                               (menu-bar-lines . ,new-visibility)))
    (message "%s %s"
             (if (= new-visibility 1) "Enabled" "Disabled")
             (if (= new-visibility 1) "tool‑bar & menu‑bar" "tool‑bar & menu‑bar"))))

(global-set-key (kbd "C-c t") #'my/toggle-tool-and-menu-bars)

(provide 'core-ui)
;;; core-ui.el ends here
