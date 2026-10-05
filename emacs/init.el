(setq custom-file "~/.emacs.custom.el")

(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(menu-bar-mode -1)
(set-fringe-mode 2)
(global-display-line-numbers-mode 1)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 8)

(defun my-c-c++-style ()
  (setq-local c-basic-offset 8)
  (setq-local tab-width 8)
  (setq-local indent-tabs-mode nil)) ; use spaces

(add-hook 'c-mode-common-hook #'my-c-c++-style)


(set-face-attribute 'default nil :font "0xProto Regular" :height  120)

(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)
(use-package command-log-mode)

;; fonts
(use-package nerd-icons
  :custom
  (nerd-icons-font-family "Symbols Nerd Font Mono")
  )

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(use-package doom-themes
  :ensure t
  :custom
  ;; Global settings (defaults)
  (doom-themes-enable-bold t)   ; if nil, bold is universally disabled
  (doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; for treemacs users
  :config
  (load-theme 'doom-bluloco-dark t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;; whitespace setup
(use-package whitespace
  :custom
  (whitespace-display-mappings
   '(
     (space-mark 32 [183] [46])
     (tab-mark 9 [187 9] [92 9])
     ))
  (whitespace-style '(face spaces tabs trailing space-mark tab-mark))
  :config
  (global-whitespace-mode 1))

(defun clean-trailing-whitespace (&rest _args)
  (whitespace-cleanup)
  (message "Cleaning all whitespace!"))

(advice-add 'save-some-buffers :before #'clean-trailing-whitespace)

;; smex for remember commands with ivy command execute
(use-package smex)
(smex-initialize)
;; setting up ivy mode

(use-package swiper)

(use-package ivy
  :diminish
  :bind (("C-s" . swiper-isearch))
  :config
  (ivy-mode 1)
  )

(use-package counsel
  :diminish
  :config
  (setq counsel-M-x-collection 'smex)
  (counsel-mode 1))

(use-package rust-mode
  :init
  (add-hook 'rust-mode-hook
            (lambda () (setq indent-tabs-mode nil)))
  (setq rust-format-on-save t)
  )

(use-package magit
  :commands (magit-status magit-get-current-branch)
  :custom(magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  )

(use-package hl-todo
  :config
  (setq hl-todo-keyword-faces
        '(("TODO"   . "#FF0000")
          ("SAFETY"   . "#00FF00")))
  (global-hl-todo-mode)
  )

;; auto complete
(use-package company
  :config
  (global-company-mode 1))

(use-package markdown-mode)

(use-package multiple-cursors)

(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
