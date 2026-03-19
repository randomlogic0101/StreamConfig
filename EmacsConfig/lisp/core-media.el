;;; core-media.el -*- lexical-binding: t; -*-

(use-package mpv
  :commands (mpv-play)
  :custom
  (mpv-default-arguments '("--ytdl-format=bestvideo+bestaudio"))
  :config
  ;; Play URL inside the current EXWM window using --wid
  (defun my/mpv-play-url (url)
    "Play a media URL using mpv inside the current EXWM window."
    (interactive "sURL: ")
    (if (bound-and-true-p exwm--id)
        (let ((wid (number-to-string exwm--id)))
          (start-process "mpv" nil "mpv" "--no-terminal" "--wid" wid url))
      ;; fallback if not in EXWM
      (start-process "mpv" nil "mpv" "--no-terminal" url)))

  ;; Play URL at point
  (defun my/mpv-play-at-point ()
    (interactive)
    (if-let ((url (thing-at-point 'url t)))
        (my/mpv-play-url url)
      (user-error "No URL at point")))

  ;; Keybindings
  :bind (("C-c v p" . my/mpv-play-at-point)
         ("C-c v u" . my/mpv-play-url)))

(provide 'core-media)
;;; core-media.el ends here
