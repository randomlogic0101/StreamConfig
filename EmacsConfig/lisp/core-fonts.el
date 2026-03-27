;;; core-fonts.el -*- lexical-binding: t; -*-

(defun my/apply-font (font)
  (set-face-attribute 'default nil
                      :family font
                      :height 110)) ;; readability

(let ((preferred '("FiraCode Nerd Font Mono"
                   "Hack Nerd Font"
                   "JetBrainsMono Nerd Font")))
  (when-let ((font (seq-find
                    (lambda (f) ;; earlier you have used (lambda () on a newline, here it was not, use one style, try to avoid using multiple at once
                      (member f (font-family-list)))
                    preferred)))
    (my/apply-font font)))

(global-set-key (kbd "C-=")
                (lambda () (interactive)
                  (set-face-attribute 'default nil
                                      :height
                                      (+ (face-attribute 'default :height) 10))))

(global-set-key (kbd "C--")
                (lambda () (interactive)
                  (set-face-attribute 'default nil
                                      :height
                                      (- (face-attribute 'default :height) 10))))

(provide 'core-fonts)
