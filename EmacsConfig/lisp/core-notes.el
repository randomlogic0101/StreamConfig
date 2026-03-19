;;; core-notes.el -*- lexical-binding: t; -*-

(use-package markdown-mode)

(use-package obsidian
  :custom
  (obsidian-directory "~/Documents/Vaults/Notes")
  (obsidian-inbox-directory "Inbox")
  (markdown-enable-wiki-links t)
  :bind (:map obsidian-mode-map
              ("C-c C-n" . obsidian-capture)
              ("C-c C-l" . obsidian-insert-link)
              ("C-c C-o" . obsidian-follow-link-at-point)))

(provide 'core-notes)