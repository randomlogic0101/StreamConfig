;;; core-exwm.el --- EXWM + embedded MPV -*- lexical-binding: t; -*-

(defvar my/exwm-enabled
  (string= (getenv "EMACS_EXWM") "1")
  "Non-nil when EXWM should start.")

;; ---------------------------------------
;; MPV embedding helper
;; ---------------------------------------
(defun my/mpv--geometry ()
  "Return WIDTHxHEIGHT of current window in pixels."
  (format "%dx%d"
          (window-pixel-width)
          (window-pixel-height)))

;; ---------------------------------------
;; EXWM setup
;; ---------------------------------------
(when my/exwm-enabled
  ;; Force minibuffer in main frame
  (setq enable-recursive-minibuffers t) ;; this should always be on, not just in exwm
  (setq initial-frame-alist '((minibuffer . t)))
  (setq minibuffer-frame nil)

  ;; Use-package for EXWM
  (use-package exwm
    :ensure t
    :config
    ;; Load modules
    (require 'exwm)
    (require 'exwm-input)
    (require 'exwm-systemtray)

    ;; Core EXWM settings
    (setq exwm-workspace-number 1
          exwm-workspace-show-minibuffer t
          exwm-workspace-show-all-buffers t
          exwm-layout-show-all-buffers t
          exwm-workspace-minibuffer-position 'bottom)

    ;; -------------------------------
    ;; Global keybindings
    ;; -------------------------------
    (setq exwm-input-global-keys
          `(
            ;; Release keyboard for line-mode
            ([?\C-c ?\C-k] . exwm-input-release-keyboard)
            ;; Text scaling
            ([?\C-+] . text-scale-increase)
            ([?\C--] . text-scale-decrease)
            ;; App launchers
            ([?\C-c ?f] . my/exwm-firefox) ;; not icecat, based on gnu mozzila fork gnuzilla?
            ([?\C-c ?m] . my/exwm-mpv)
            ;; New EXWM window
            ([?\C-c ?n] . my/exwm-new-window)
            ;; MPV play-in-exwm
            ([?\C-c ?p] . my/mpv-play-in-exwm)
            ))

    ;; -------------------------------
    ;; EXWM window behavior
    ;; -------------------------------
    (setq exwm-manage-configurations
          '(((lambda (_win _class _instance _title) t)
             floating nil
             char-mode nil))) ;; nil => line mode by default

    ;; -------------------------------
    ;; Hooks for new EXWM buffers
    ;; -------------------------------
    (defun my/exwm-manage-hook ()
      "Hook for new EXWM buffers: adopt buffer, place, replace, line-mode."
      (my/exwm-place-in-current-window)
      (my/exwm-replace-buffer)
      ;; Default to line mode unless MPV
      (unless (string= exwm-class-name "mpv")
        (exwm-input-release-keyboard)))

    (add-hook 'exwm-manage-finish-hook #'my/exwm-manage-hook)

    ;; Enable EXWM
    ;;(exwm-enable))
    (exwm-wm-mode))

  ;; ---------------------------------------
  ;; Helper functions
  ;; ---------------------------------------

(defun my/exwm-adopt-buffer (buffer-or-command)
  "Ensure BUFFER-OR-COMMAND is an EXWM buffer.
BUFFER-OR-COMMAND can be a buffer (converted to EXWM) or a COMMAND string to launch."
  (cond
   ((bufferp buffer-or-command)
    (with-current-buffer buffer-or-command
      ;; Only enable exwm-mode if it's not already an EXWM buffer
      (unless (eq major-mode 'exwm-mode)
        (exwm-mode))
      ;; Place in current window
      (my/exwm-place-in-current-window)
      buffer-or-command))
   ((stringp buffer-or-command)
    ;; Launch X app asynchronously
    (my/exwm-launch buffer-or-command))
   (t (error "Invalid argument to my/exwm-adopt-buffer"))))

;;  (defun my/exwm-adopt-buffer (buffer-or-command)
;;    "Ensure BUFFER-OR-COMMAND is an EXWM buffer.
;; BUFFER-OR-COMMAND can be a buffer (converted to EXWM) or a COMMAND string to launch."
;;    (cond
;;     ((bufferp buffer-or-command)
;;      (with-current-buffer buffer-or-command
;;        (unless (eq major-mode 'exwm-mode)
;;          (exwm-manage--maybe-track-window (selected-window))
;;          (exwm-mode))
;;        (my/exwm-place-in-current-window)
;;        buffer-or-command))
;;     ((stringp buffer-or-command)
;;      (my/exwm-launch buffer-or-command))
;;     (t (error "Invalid argument to my/exwm-adopt-buffer"))))

  (defun my/exwm-place-in-current-window ()
    "Force EXWM buffer into selected window."
    (when (eq major-mode 'exwm-mode)
      (set-window-buffer (selected-window) (current-buffer))))

  (defun my/exwm-replace-buffer ()
    "Replace current buffer with EXWM window."
    (when (eq major-mode 'exwm-mode)
      (switch-to-buffer (current-buffer))))

  (defun my/exwm-launch (command)
    "Launch X app."
    (interactive "sRun: ")
    (start-process-shell-command command nil command))

  ;; Launchers
  (defun my/exwm-firefox ()
    "Launch or adopt Firefox."  ;; icecat, see above
    (interactive)
    (my/exwm-adopt-buffer "firefox"))

  (defun my/exwm-mpv ()
    "Launch or adopt MPV."
    (interactive)
    (my/exwm-adopt-buffer "mpv"))

  (defun my/mpv-play-in-exwm (file)
  "Play FILE with mpv embedded in current EXWM window."
  (interactive (list (read-file-name "Video file: ")))
  ;; Make sure current buffer is an EXWM buffer
  (let ((buf (my/exwm-adopt-buffer (current-buffer))))
    (unless (and buf (bound-and-true-p exwm--id))
      (error "Current buffer is not an EXWM window"))
    ;; Now compute geometry after confirming exwm--id
    (let* ((wid exwm--id)
           (geom (my/mpv--geometry))
           (cmd (format "mpv --wid=%d --geometry=%s --no-border --quiet \"%s\""
                        wid geom (expand-file-name file))))
      (start-process "mpv-exwm" nil "sh" "-c" cmd)
      (message "Started mpv (wid %d, geometry %s)" wid geom))))

  ;; General-purpose "new EXWM window" helper
  (defun my/exwm-new-window ()
  "Launch a new X window in the current window in line mode."
  (interactive)
  ;; Launch minimal X terminal to get a real EXWM window
  (let ((buf (my/exwm-adopt-buffer "xterm"))) ; or "urxvt", "alacritty", etc.
    ;; Place it in current window and ensure line mode
    (when buf
      (with-current-buffer buf
        (my/exwm-place-in-current-window)
        (exwm-input-release-keyboard)))))
;;; just a thought, could a keybind to open ansi-term be of use?

  ;; ---------------------------------------
  ;; Startup layout: left full-height, right split vertically
  ;; ---------------------------------------
  (add-hook 'emacs-startup-hook
          (lambda ()
            ;; Delete other ordinary windows, preserve minibuffer
            (let ((windows (seq-filter (lambda (w)
                                         (not (window-minibuffer-p w)))
                                       (window-list))))
              (dolist (w (cdr windows))
                (delete-window w)))

            ;; Split left/right
            (let ((left (selected-window))
                  right)
              (setq right (split-window left nil t)) ;; vertical split
              ;; Split right vertically
              (split-window right nil nil)
              ;; Select left window
              (select-window left))

            ;; Fullscreen frame
            (set-frame-parameter nil 'fullscreen 'fullboth)))

  ;; ---------------------------------------
  ;; Quit shortcut
  ;; ---------------------------------------
  (global-set-key
   (kbd "C-c q")
   (lambda ()
     (interactive)
     (save-some-buffers t)
     (kill-emacs))))

(provide 'core-exwm)
