;;; package -- Matt Russell's custom emacs setup
;;;
;;; Commentary:
;;; Integrates with netsight-emacs.
;;; Customisations:
;;;  - Adapts python-mode to work with differnet project styles,
;;;    notably the Pylons project.
;;
(setq debug-on-error t)
;;; Code:
(require 'ido)
(require 'magit)
(require 'org)
(require 'org-install)
(require 'python)
(require 'rst)
(require 's)

(setq-default dired-omit-files-p t)
(setq custom-theme-directory (locate-user-emacs-file "themes"))

(ido-mode 1)
(setq ido-case-fold t)
(setq ido-everywhere t)
(setq ido-enable-prefix nil)
(setq ido-enable-flex-matching t)
(setq ido-create-new-buffer 'always)
(setq ido-max-prospects 10)
(setq ido-file-extensions-order
      '(".py" ".zcml" ".el" ".xml" ".js"))

;; org-mode
(setq org-log-done t)
(setq org-agenda-files (list "~/org/work.org"))
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   ))

(setq-default theme-load-from-file t)
(setq-default theme-default 'solarized-dark)
(menu-bar-mode 1)
(set-fill-column 79)

(defun setup-global-key-bindings ()
  "Setup global key bindings."
  (require 'magit)
  (require 'org)
  (global-set-key (kbd "C-c +") 'text-scale-increase)
  (global-set-key (kbd "C-c -") 'text-scale-decrease)
  (global-set-key (kbd "C-c l") 'org-store-link)
  (global-set-key (kbd "C-c c") 'org-capture)
  (global-set-key (kbd "C-c a") 'org-agenda)
  (global-set-key (kbd "C-c b") 'org-iswitchb)
  (global-set-key (kbd "C-c m") 'magit-status))

(add-hook #'after-init-hook #'setup-global-key-bindings)

(defvar py-workon-home (or (getenv "WORKON_HOME") "~/.virtualenvs")
  "The virtualenvwrapper stuff.")

(defvar pylons-git-repos
  (list "colander.git"
	"deform.git"
	"peppercorn.git"
	"pyramid.git"
	"pyramid_chameleon.git"
	"pyramid_mako.git"
	"pyramid_layout.git"
	"pyramid_ldap"
	"pyramid_zcml.git"
	"pyramid_zodbconn.git"
	"sdidemo.git"
	"substanced.git"))

(defun is-pylons-repo (url)
  "Return true if URL is a Pylons repository."
  (delq nil (mapcar (lambda (repo-suffix)
		      (s-suffix? repo-suffix url))
		    pylons-git-repos)))


(defun git-get-current-remote-name ()
  "Get the current git remote name if any."
  (let* ((branch  (magit-get-current-branch))
         (remote (magit-get "branch" branch "remote")))
    (when remote
      (magit-get "remote" remote "url"))))

(defun py-set-flycheck-flake8rc-for-current-git-repo()
  (require 'flycheck)
  (let* ((curr-git-remote-url (git-get-current-remote-name))
	 (flake8rc-filename "flake8rc"))
    (if (is-pylons-repo curr-git-remote-url)
	(setq flake8rc-filename "pylons.flake8rc"))
    (setq-default flycheck-flake8rc (concat "~/.config/" flake8rc-filename))))

(defun pyvenv-activate-safely (directory)
  "Use instead of pyvenv-activate to strip trailing slash from DIRECTORY."
  (interactive "DEnter Path to directory containing bin/activate:")
  (pyvenv-activate (directory-file-name directory)))

(defun py-venv-known-names (directory)
  "List `known` virtualenvs names only in DIRECTORY."
  (let* ((dir-name (directory-file-name directory))
	 (full-names 1)
	 (files (directory-files directory full-names))
	 (dirs (remove-if-not #'file-directory-p files))
	 (names (remove-if #'(lambda (name) (s-match ".+\\.+$" name)) dirs)))
    (mapcar #'file-name-base names)))

(defun py-auto-workon-maybe ()
  "Attempt to automatically workon known virtualenvs."
  (require 'pyvenv)
  (let* ((git-remote-name (git-get-current-remote-name))
	 (git-repo-name (or (file-name-base git-remote-name) ""))
	 (venv-names (py-venv-known-names py-workon-home))
	 (venvs-matched
	  (remove-if-not
	   #'(lambda (venv-name) (s-contains? git-repo-name venv-name))
	   venv-names)))
    (if (and (> 1 (length venvs-matched)) pyvenv-virtual-env)
	(pyvenv-deactivate)
      (pyvenv-workon (car venvs-matched)))))


(defun py-handle-virtualenvs ()
  "Handle Python virualenvs."
  (pyvenv-mode 1)
  (define-key python-mode-map (kbd "C-c w") 'pyvenv-workon)
  (define-key python-mode-map (kbd "C-c v d") 'pyvenv-deactivate)
  (define-key python-mode-map (kbd "C-c v e") 'pyvenv-activate-safely))

(defun py-handle-sphinx-docs ()
  "Handle Sphinx docs doing python reference lookups using virtualenvs."
  (auto-fill-mode t)
  (handle-virtualenvs))

(defun py-setup ()
  "Setup Python developemnt environment."
  (py-auto-workon-maybe)
  (py-handle-virtualenvs)
  (py-set-flycheck-flake8rc-for-current-git-repo))

(add-hook 'python-mode-hook #'py-setup)
(add-hook 'rst-mode #'py-handle-sphinx-docs)

(add-hook 'dired-load-hook
	  '(lambda ()
	     (dired-omit-mode 1)))

(setq-default jabber-account-list
    '((:password: nil)
      (:network-server . "")
      (:port 5220)
      (:connection-type . ssl)))
(require 'notify)


(defun notify-jabber-notify (from buf text proposed-alert)
  "Notify via notify.el about new messages using FROM BUF TEXT PROPOSED-ALERT."
  (when (or jabber-message-alert-same-buffer
            (not (memq (selected-window) (get-buffer-window-list buf))))
    (if (jabber-muc-sender-p from)
        (notify (format "(PM) %s"
                       (jabber-jid-displayname (jabber-jid-user from)))
               (format "%s: %s" (jabber-jid-resource from) text)))
      (notify (format "%s" (jabber-jid-displayname from))
             text)))

(add-hook 'jabber-alert-message-hooks 'notify-jabber-notify)
(provide '.emacs-custom)
;;; .emacs-custom.el ends here
