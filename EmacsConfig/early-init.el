;;; early-init.el --- Early init  -*- lexical-binding: t; -*-
;;; Commentary:
;;   TODO: Figure out how to combine bootstrap, and platform checks to eliminate
;;     redundant code, and warnings
;;
;;; Code:

;; Must be first because early-init doesn't have a reliable path setup
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;;; Private internal constants
(setq --bootstrap-lib "core-bootstrap") ;; Lib name for platform bootstrapping
(setq --bootstrap-warn-format "
==============================================================================
early-init WARNING: Platform bootstrap library not found
==============================================================================

Expected location: %s

Without platform detection (NixOS, MacOS, Win32, etc.) default configurations
will be used which may fail on your platform.

Troubleshooting:
1. Verify the file exists at the expected location
2. Check case sensitivity (Unix/Linux/macOS are case-sensitive)
3. If using git: ensure all files are tracked and not ignored
4. If in Docker: verify volume mounts include the lisp directory
5. If using NixOS: ensure the config is properly deployed
6. If using stow ensure .emacs.d is correctly stowed
==============================================================================
")

;;; Critical dependency check
;;   --bootstrap-lib sets two critical variables core--platform, and
;;   core--in-container. Many configurations will depend on these.
;;   However, if --bootstrap-lib is not set, configurations are expected to
;;   have sane fallback defaults.
;;
;;   Error fallback:
;;     core--platform = "unknown"
;;     core--in-container = "nil"
(let ((bootstrap-lib (locate-library --bootstrap-lib)))
  (if bootstrap-lib
    (load bootstrap-lib nil t t)
    (progn
      (display-warning (intern --bootstrap-lib) (format --bootstrap-warn-format
        (format "%slisp/%s.el" user-emacs-directory --bootstrap-lib)))
      (unless (boundp 'core--platform)
        (setq core--platform "unknown"))
      (unless (boundp 'core--in-container)
        (setq core--in-container nil))
    )))

(defun core--run-platform-init ()
  "Dispatch to the correct platform-specific initialization function."
  (let ((func-name (intern (format "core--%s-init" core--platform)))
    (fallback 'core--generic-init))
    (if (fboundp func-name)
      (progn
        (message "core-bootstrap: Running %s initialization" core--platform)
        (funcall func-name))
      (progn
        (message "core-bootstrap: falling back to generic init" core--platform)
        (funcall fallback)))))

;; Disable package.el at startup (we control it)
(setq package-enable-at-startup nil
      ;; Faster startup
      gc-cons-threshold most-positive-fixnum)

;; Disable UI early
(push '(menu-bar-lines . 0)         default-frame-alist)
(push '(tool-bar-lines . 0)         default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

(core--run-platform-init)
(message "core-bootstrap: Initialized for %s (Container: %s)"
  core--platform
  (if core--in-container "YES" "NO"))

(provide 'early-init)
;;; early-init.el ends here
