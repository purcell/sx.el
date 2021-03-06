;;; sx-tab.el --- Functions for viewing different tabs.       -*- lexical-binding: t; -*-

;; Copyright (C) 2014  Artur Malabarba

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;


;;; Code:

(require 'sx)
(require 'sx-question-list)

(defcustom sx-tab-default-site "emacs"
  "Name of the site to use by default when listing questions."
  :type 'string
  :group 'sx)

(defvar sx-tab--list nil
  "List of the names of all defined tabs.")

(defun sx-tab-switch (tab)
  "Switch to another question-list tab."
  (interactive
   (list (funcall (if ido-mode #'ido-completing-read #'completing-read)
           "Switch to tab: " sx-tab--list
           (lambda (tab) (not (equal tab sx-question-list--current-tab)))
           t)))
  (funcall (intern (format "sx-tab-%s" (downcase tab)))))

(defun sx-tab--interactive-site-prompt ()
  "Query the user for a site."
  (let ((default (or sx-question-list--site
                     (sx-assoc-let sx-question-mode--data
                       .site)
                     sx-tab-default-site)))
    (funcall (if ido-mode #'ido-completing-read #'completing-read)
      (format "Site (%s): " default)
      (sx-site-get-api-tokens) nil t nil nil
      default)))


;;; The main macro
(defmacro sx-tab--define (tab pager &optional printer refresher
                              &rest body)
  "Define a StackExchange tab called TAB.
TAB is a capitalized string.

This defines a command `sx-tab-TAB' for displaying the tab,
and a variable `sx-tab--TAB-buffer' for holding the bufer.

The arguments PAGER, PRINTER, and REFRESHER, if non-nil, are
respectively used to set the value of the variables
`sx-question-list--print-function',
`sx-question-list--refresh-function', and
`sx-question-list--next-page-function'.

BODY is evaluated after activating the mode and setting these
variables, but before refreshing the display."
  (declare (indent 1) (debug t))
  (let* ((name (downcase tab))
         (buffer-variable
          (intern (concat "sx-tab--" name "-buffer"))))
    `(progn
       (defvar ,buffer-variable nil
         ,(format "Buffer where the %s questions are displayed."
            tab))
       (defun
           ,(intern (concat "sx-tab-" name))
           (&optional no-update site)
         ,(format "Display a list of %s questions for SITE.

NO-UPDATE (the prefix arg) is passed to `sx-question-list-refresh'.
If SITE is nil, use `sx-tab-default-site'."
            tab)
         (interactive
          (list current-prefix-arg
                (sx-tab--interactive-site-prompt)))
         (sx-initialize)
         (unless site (setq site sx-tab-default-site))
         ;; Create the buffer
         (unless (buffer-live-p ,buffer-variable)
           (setq ,buffer-variable
                 (generate-new-buffer "*question-list*")))
         ;; Fill the buffer with content.
         (with-current-buffer ,buffer-variable
           (sx-question-list-mode)
           ,(when printer
              `(setq sx-question-list--print-function ,printer))
           ,(when refresher
              `(setq sx-question-list--refresh-function ,refresher))
           ,(when pager
              `(setq sx-question-list--next-page-function ,pager))
           (setq sx-question-list--site site)
           (setq sx-question-list--current-tab ,tab)
           ,@body
           (sx-question-list-refresh 'redisplay no-update))
         (switch-to-buffer ,buffer-variable))
       ;; Add this tab to the list of existing tabs. So we can prompt
       ;; the user with completion and stuff.
       (add-to-list 'sx-tab--list ,tab))))


;;; FrontPage
(sx-tab--define "FrontPage"
  (lambda (page)
    (sx-question-get-questions
     sx-question-list--site page '((sort . activity)))))
;;;###autoload
(autoload 'sx-tab-frontpage
  (expand-file-name
   "sx-tab"
   (when load-file-name
     (file-name-directory load-file-name)))
  nil t)


;;; Newest
(sx-tab--define "Newest"
  (lambda (page)
    (sx-question-get-questions
     sx-question-list--site page '((sort . creation)))))
;;;###autoload
(autoload 'sx-tab-newest
  (expand-file-name
   "sx-tab"
   (when load-file-name
     (file-name-directory load-file-name)))
  nil t)



;;; TopVoted
(sx-tab--define "TopVoted"
  (lambda (page)
    (sx-question-get-questions
     sx-question-list--site page '((sort . votes)))))
;;;###autoload
(autoload 'sx-tab-topvoted
  (expand-file-name
   "sx-tab"
   (when load-file-name
     (file-name-directory load-file-name)))
  nil t)



;;; Hot
(sx-tab--define "Hot"
  (lambda (page)
    (sx-question-get-questions
     sx-question-list--site page '((sort . hot)))))
;;;###autoload
(autoload 'sx-tab-hot
  (expand-file-name
   "sx-tab"
   (when load-file-name
     (file-name-directory load-file-name)))
  nil t)



;;; Week
(sx-tab--define "Week"
  (lambda (page)
    (sx-question-get-questions
     sx-question-list--site page '((sort . week)))))
;;;###autoload
(autoload 'sx-tab-week
  (expand-file-name
   "sx-tab"
   (when load-file-name
     (file-name-directory load-file-name)))
  nil t)



;;; Month
(sx-tab--define "Month"
  (lambda (page)
    (sx-question-get-questions
     sx-question-list--site page '((sort . month)))))
;;;###autoload
(autoload 'sx-tab-month
  (expand-file-name
   "sx-tab"
   (when load-file-name
     (file-name-directory load-file-name)))
  nil t)

(provide 'sx-tab)
;;; sx-tab.el ends here
