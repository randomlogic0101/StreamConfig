;;; early-init.el --- Early init  -*- lexical-binding: t; -*-

;; Disable package.el at startup (we control it)
(setq package-enable-at-startup nil
      ;; Faster startup
      gc-cons-threshold most-positive-fixnum)

;; Disable UI early
(push '(menu-bar-lines . 0)         default-frame-alist)
(push '(tool-bar-lines . 0)         default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

;;; early-init.el ends here
