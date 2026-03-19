;;; core-dired.el -*- lexical-binding: t -*-

;; Dired basic configuration
(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-alh --group-directories-first"))

;; Privacy mode flag
(defvar my/dired-privacy-mode t
  "Non-nil means anonymize owner/group and home paths in Dired buffers.")

;; Helper function to anonymize home directory in line
(defun my/dired-abbrev-home-line ()
  "Replace occurrences of /home/<user> with ~ in current line."
  (let ((inhibit-read-only t)
        (home (expand-file-name "~")))
    (save-excursion
      (beginning-of-line)
      (while (search-forward home (line-end-position) t)
        (replace-match "~" t t)))))

;; Overlay function for owner/group columns
(defun my/dired-overlay-owner-group ()
  "Visually replace owner/group in current line with 'Gamer'."
  (when (looking-at "^\\([drwxl-]+ +\\)\\([^ ]+\\) +\\([^ ]+\\)")
    ;; overlay owner
    (let ((ov (make-overlay (match-beginning 2) (match-end 2))))
      (overlay-put ov 'display "Gamer")
      (overlay-put ov 'evaporate t))
    ;; overlay group
    (let ((ov (make-overlay (match-beginning 3) (match-end 3))))
      (overlay-put ov 'display "Gamer")
      (overlay-put ov 'evaporate t))))

;; Main function to apply privacy overlays in entire buffer
(defun my/dired-anonymize-buffer ()
  "Anonymize owner/group and home paths in the current Dired buffer."
  (when (and my/dired-privacy-mode (derived-mode-p 'dired-mode))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (my/dired-abbrev-home-line)
        (my/dired-overlay-owner-group)
        (forward-line 1)))))

;; Hook to run after Dired finishes reading a directory
(add-hook 'dired-after-readin-hook #'my/dired-anonymize-buffer)

;;;###autoload
(defun my/dired-toggle-privacy-mode ()
  "Toggle anonymization of owner/group and home paths in Dired buffers."
  (interactive)
  (setq my/dired-privacy-mode (not my/dired-privacy-mode))
  (message "Dired privacy mode %s"
           (if my/dired-privacy-mode "enabled" "disabled"))
  ;; Refresh all Dired buffers to apply/remove overlays
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (derived-mode-p 'dired-mode)
        (revert-buffer)))))

(provide 'core-dired)
