;;; init.el --- Prelude's configuration entry point.
;;
;; Copyright (c) 2011-2021 Bozhidar Batsov
;;
;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: https://github.com/bbatsov/prelude
;; Version: 1.1.0
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file simply sets up the default load path and requires
;; the various modules defined within Emacs Prelude.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
;(package-initialize)

(defvar prelude-user
  (getenv
   (if (equal system-type 'windows-nt) "USERNAME" "USER")))

(message "[Prelude] Prelude is powering up... Be patient, Master %s!" prelude-user)

(when (version< emacs-version "25.1")
  (error "[Prelude] Prelude requires GNU Emacs 25.1 or newer, but you're running %s" emacs-version))

;; Always load newest byte code
(setq load-prefer-newer t)

;; Define Prelude's directory structure
(defvar prelude-dir (file-name-directory load-file-name)
  "The root dir of the Emacs Prelude distribution.")
(defvar prelude-core-dir (expand-file-name "core" prelude-dir)
  "The home of Prelude's core functionality.")
(defvar prelude-modules-dir (expand-file-name  "modules" prelude-dir)
  "This directory houses all of the built-in Prelude modules.")
(defvar prelude-personal-dir (expand-file-name "personal" prelude-dir)
  "This directory is for your personal configuration.

Users of Emacs Prelude are encouraged to keep their personal configuration
changes in this directory.  All Emacs Lisp files there are loaded automatically
by Prelude.")
(defvar prelude-personal-preload-dir (expand-file-name "preload" prelude-personal-dir)
  "This directory is for your personal configuration, that you want loaded before Prelude.")
(defvar prelude-vendor-dir (expand-file-name "vendor" prelude-dir)
  "This directory houses packages that are not yet available in ELPA (or MELPA).")
(defvar prelude-savefile-dir (expand-file-name "savefile" user-emacs-directory)
  "This folder stores all the automatically generated save/history-files.")
(defvar prelude-modules-file (expand-file-name "prelude-modules.el" prelude-personal-dir)
  "This file contains a list of modules that will be loaded by Prelude.")

(unless (file-exists-p prelude-savefile-dir)
  (make-directory prelude-savefile-dir))

(defun prelude-add-subfolders-to-load-path (parent-dir)
  "Add all level PARENT-DIR subdirs to the `load-path'."
  (dolist (f (directory-files parent-dir))
    (let ((name (expand-file-name f parent-dir)))
      (when (and (file-directory-p name)
                 (not (string-prefix-p "." f)))
        (add-to-list 'load-path name)
        (prelude-add-subfolders-to-load-path name)))))

;; add Prelude's directories to Emacs's `load-path'
(add-to-list 'load-path prelude-core-dir)
(add-to-list 'load-path prelude-modules-dir)
(add-to-list 'load-path prelude-vendor-dir)
(prelude-add-subfolders-to-load-path prelude-vendor-dir)

;; reduce the frequency of garbage collection by making it happen on
;; each 50MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)

;; preload the personal settings from `prelude-personal-preload-dir'
(when (file-exists-p prelude-personal-preload-dir)
  (message "[Prelude] Loading personal configuration files in %s..." prelude-personal-preload-dir)
  (mapc 'load (directory-files prelude-personal-preload-dir 't "^[^#\.].*el$")))

(message "[Prelude] Loading Prelude's core modules...")

;; load the core stuff
(require 'prelude-packages)
(require 'prelude-custom)  ;; Needs to be loaded before core, editor and ui
(require 'prelude-ui)
(require 'prelude-core)
(require 'prelude-mode)
(require 'prelude-editor)
(require 'prelude-global-keybindings)

;; macOS specific settings
(when (eq system-type 'darwin)
  (require 'prelude-macos))

;; Linux specific settings
(when (eq system-type 'gnu/linux)
  (require 'prelude-linux))

;; WSL specific setting
(when (and (eq system-type 'gnu/linux) (getenv "WSLENV"))
  (require 'prelude-wsl))

;; Windows specific settings
(when (eq system-type 'windows-nt)
  (require 'prelude-windows))

(message "[Prelude] Loading Prelude's additional modules...")

;; the modules
(if (file-exists-p prelude-modules-file)
    (load prelude-modules-file)
  (message "[Prelude] Missing personal modules file %s" prelude-modules-file)
  (message "[Prelude] Falling back to the bundled example file sample/prelude-modules.el")
  (message "[Prelude] You should copy this file to your personal configuration folder and tweak it to your liking")
  (load (expand-file-name "sample/prelude-modules.el" user-emacs-directory)))

;; config changes made through the customize UI will be stored here
(setq custom-file (expand-file-name "custom.el" prelude-personal-dir))

;; load the personal settings (this includes `custom-file')
(when (file-exists-p prelude-personal-dir)
  (message "[Prelude] Loading personal configuration files in %s..." prelude-personal-dir)
  (mapc 'load (delete
               prelude-modules-file
               (directory-files prelude-personal-dir 't "^[^#\.].*\\.el$"))))

(message "[Prelude] Prelude is ready to do thy bidding, Master %s!" prelude-user)

;; Patch security vulnerability in Emacs versions older than 25.3
(when (version< emacs-version "25.3")
  (with-eval-after-load "enriched"
    (defun enriched-decode-display-prop (start end &optional param)
      (list start end))))

(prelude-eval-after-init
 ;; greet the use with some useful tip
 (run-at-time 5 nil 'prelude-tip-of-the-day))


;; user configuration starts here
;; (autoload 'scheme-mode "cmuscheme" "Major mode for Scheme." t)
;; (autoload 'run-scheme "cmuscheme" "Switch to interactive Scheme buffer." t)
;; (setq auto-mode-alist (cons '("\\.ss" . scheme-mode) auto-mode-alist))

(setq load-path (cons "~/emacs" load-path))

;; (autoload 'scheme-mode "iuscheme" "Major mode for Scheme." t)
;; (autoload 'run-scheme "iuscheme" "Switch to interactive Scheme buffer." t)
;; (setq auto-mode-alist (cons '("\\.ss" . scheme-mode) auto-mode-alist))

(put 'form-id 'scheme-indent-function 2)

;; for company-anaconda

;; associate asm-lsp with assembly file modes

;; Set up `lsp-mode` for assembly
(use-package lsp-mode
  :ensure t
  :hook (asm-mode . lsp)
  :commands lsp
  :config
  (setq lsp-asm-lsp-server-command '("/home/perryman/.cargo/bin/asm-lsp"))
  (with-eval-after-load 'lsp-mode
    (add-to-list 'lsp-language-id-configuration '(asm-mode . "asm"))))

;; Optionally install `lsp-ui`
(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode)

;; Ensure `.asm` and `.s` files are recognized correctly
(add-to-list 'auto-mode-alist '("\\.\\(asm\\|s\\)$" . asm-mode))

;; Register asm-lsp with lsp-mode
(with-eval-after-load 'lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("/home/perryman/.cargo/bin/asm-lsp"))
    :major-modes '(asm-mode nasm-mode gas-mode)
    :server-id 'asm-lsp))
  (add-to-list 'lsp-language-id-configuration '(asm-mode . "asm")))

(setq lsp-auto-guess-root t)

;;; init.el ends here
(put 'scroll-left 'disabled nil)

(remove-hook 'prog-mode-hook #'whitespace-mode) ; (global-whitespace-mode -1)

;; scheme
(add-hook 'scheme-mode-hook #'rainbow-delimiters-mode)
(add-hook 'scheme-mode-hook #'rainbow-identifiers-mode)
(add-hook 'scheme-mode-hook (lambda () (whitespace-mode -1)))
(add-hook 'scheme-mode-hook (lambda () (comment-set-column 0)))

;; Geiser
;  hook rainbow delimiters, identifiers, and turn off whitespace
(add-hook 'geiser-mode-hook #'rainbow-delimiters-mode)
(add-hook 'geiser-mode-hook #'rainbow-identifiers-mode)
(add-hook 'geiser-mode-hook (lambda () (whitespace-mode -1)))

;; Enable rainbow-identifiers globally
(add-hook 'prog-mode-hook #'rainbow-identifiers-mode)
(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)
(add-hook 'geiser-repl-mode-hook #'rainbow-identifiers-mode)
(add-hook 'geiser-repl-mode-hook #'rainbow-delimiters-mode)
(add-hook 'geiser-debug-mode-hook #'rainbow-identifiers-mode)
(add-hook 'geiser-debug-mode-hook #'rainbow-delimiters-mode)
(add-hook 'lisp-interaction-mode-hook #'rainbow-identifiers-mode)
(add-hook 'lisp-interaction-mode-hook #'rainbow-delimiters-mode)
(add-hook 'emacs-lisp-mode-hook #'rainbow-delimiters-mode)
(add-hook 'emacs-lisp-mode-hook #'rainbow-identifiers-mode)



;; Make .scm files use Scheme mode
(add-to-list 'auto-mode-alist '("\\.scm\\'" . scheme-mode))
;; Enabe Geiser whenever Scheme mode starts
(add-hook 'scheme-mode-hook
          (lambda ()
            (geiser-mode 1)
            (run-with-timer 0 nil (lambda () (run-geiser 'chez)))))

(add-hook 'scheme-mode-hook 'auto-fill-mode)

;; Custom indentation rules for Scheme in Geiser
(with-eval-after-load 'scheme
  (put '== 'scheme-indent-function 4)  ;; Indent `==` deeper
  (put '=/= 'scheme-indent-function 5) ;; Indent `=/=` even deeper
  ;;(put 'conj2 'scheme-indent-function 2) ;; conj2 clause pairing
  (setq comment-column 0) ;; semicolon comments can be at 0
  )

(with-eval-after-load 'geizer-chez
  (add-to-list 'geiser-chez-extra-keywords "defrel"))

(with-eval-after-load 'elisp
  (setq comment-column 0) ;; semicolon comments 0 indent
  )

(with-eval-after-load 'lisp
  (setq comment-column 0) ;; semicolon comments 0 indent
  )

(with-eval-after-load 'smartparens
  (sp-local-pair 'scheme-mode "`" nil :actions nil))



(winner-mode 1)

;; copilot.el config copilot-mode for auto-completions
;; (add-hook 'prog-mode-hook 'copilot-mode)
;; (with-eval-after-load 'copilot
;;   (define-key copilot-completion-map (kbd "<tab>") 'copilot-accept-completion)
;;   (define-key copilot-completion-map (kbd "TAB") 'copilot-accept-completion)
;;   (add-to-list 'copilot-major-mode-alist '("Scheme" . "scheme"))
;;   (add-to-list 'copilot-major-mode-alist '("EL" . "lisp"))
;;   )
(use-package copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)
              ("C-n" . 'copilot-next-completion)
              ("C-p" . 'copilot-previous-completion))

  :config
  (add-to-list 'copilot-indentation-alist '(prog-mode 2))
  (add-to-list 'copilot-indentation-alist '(org-mode 2))
  (add-to-list 'copilot-indentation-alist '(text-mode 2))
  (add-to-list 'copilot-indentation-alist '(closure-mode 2))
  (add-to-list 'copilot-indentation-alist '(emacs-lisp-mode 2))
  (global-set-key (kbd "C-c c") 'copilot-complete)
  (global-set-key (kbd "C-c C-p") 'copilot-mode))


;; Map window resizing to traditional keybindings
(global-set-key (kbd "S-C-<left>") 'shrink-window-horizontally)
(global-set-key (kbd "S-C-<right>") 'enlarge-window-horizontally)
(global-set-key (kbd "S-C-<up>") 'enlarge-window)
(global-set-key (kbd "S-C-<down>") 'shrink-window)
(global-set-key (kbd "C-M-y") (lambda () (interactive) (geiser-eval-last-sexp 4)))

(add-hook 'after-change-major-mode-hook
          (lambda () (text-scale-set 4)))

(setq-default comment-set-column 0)
; (setq comment-column 0)
; set rainbow mode on by default for all non-text modes
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
(add-hook 'prog-mode-hook 'rainbow-identifiers-mode)
(add-hook 'prog-mode-hook 'auto-fill-mode)
;; set company-idle-delay to 5 seconds
(add-hook 'prog-mode-hook (lambda () (setq company-idle-delay 5)))

(defalias 'sp-forward-sexp-newline-macro
  (kmacro "C-M-f RET"))
(global-set-key (kbd "C-,") 'sp-forward-sexp-newline-macro)
(global-set-key (kbd "C-<") 'delete-indentation)
(global-set-key (kbd "C-M-|") 'cycle-spacing)
(global-aggressive-indent-mode 1)
(setq-default fill-column 50)
