;;; eshell-autosuggest-overlay.el --- History autosuggestions for eshell -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Frédéric Giquel
;; Author: Frédéric Giquel <frederic.giquel@laposte.net>
;; URL: http://github.com/fredericgiquel/eshell-autosuggest-overlay
;; Git-Repository: git://github.com/fredericgiquel/eshell-autosuggest-overlay.git
;; Created: 2022-12-18
;; Version: 0.1
;; Package-Requires: (emacs "27.1")

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Provides autosuggestions from history similar to fish shell feature.

;;; Code:

(require 'ring)
(require 'em-hist)
(require 'subr-x)

(defvar-local eshell-autosuggest-overlay--current-suggestion nil
  "Current suggestion.")

(defvar-local eshell-autosuggest-overlay--current-ov nil
  "Current suggestion overlay.")

(defgroup eshell-autosuggest-overlay-faces nil
  "Faces used by eshell-autosuggest-overlay."
  :group 'eshell-autosuggest-overlay
  :group 'faces)

(defface eshell-autosuggest-overlay-face
  '((t :inherit 'font-lock-comment-face))
  "Face used for overlay.")

(defvar eshell-autosuggest-overlay-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "<right>") 'eshell-autosuggest-overlay-insert-all)
    (define-key keymap (kbd "C-f") 'eshell-autosuggest-overlay-insert-all)
    (define-key keymap (kbd "M-<right>") 'eshell-autosuggest-overlay-insert-symbol)
    (define-key keymap (kbd "M-f") 'eshell-autosuggest-overlay-insert-symbol)
    keymap)
  "Keymap that is enabled when overlay for eshell suggestions is displayed.")

(defun eshell-autosuggest-overlay--candidate (prefix)
  "Return the first eshell history candidate starting with PREFIX."
  (let ((history (mapcar (lambda (str)
                           (string-trim (substring-no-properties str)))
                         (ring-elements eshell-history-ring))))
    (seq-find (lambda (str) (string-prefix-p prefix str)) history)))

(defun eshell-autosuggest-overlay-insert-all ()
  "Insert complete suggestion."
  (interactive)
  (when eshell-autosuggest-overlay--current-suggestion
    (insert eshell-autosuggest-overlay--current-suggestion)))

(defun eshell-autosuggest-overlay-insert-symbol ()
  "Insert first symbol of suggestion."
  (interactive)
  (when-let (suggestion eshell-autosuggest-overlay--current-suggestion)
    (let* ((symbols (split-string suggestion))
           (str (if (= (length symbols) 1)
                    suggestion
                  (substring suggestion 0
                             (+ (string-search (car symbols) suggestion)
                                (length (car symbols)))))))
      (insert str))))

(defun eshell-autosuggest-overlay--display-ov ()
  "Display suggestion overlay."
  (save-excursion
    (insert (propertize " " 'face 'eshell-autosuggest-overlay-face)))
  (let ((ov (make-overlay (point) (+ 1 (point)) (current-buffer))))
    (overlay-put ov 'keymap eshell-autosuggest-overlay-map)
    (overlay-put ov 'display eshell-autosuggest-overlay--current-suggestion)
    (setq eshell-autosuggest-overlay--current-ov ov)))

(defun eshell-autosuggest-overlay--pre-command ()
  "Remove existing suggestion overlay."
  (when eshell-autosuggest-overlay--current-ov
    (delete-overlay eshell-autosuggest-overlay--current-ov)
    (setq eshell-autosuggest-overlay--current-ov nil)
    (when (and (not (equal (point) (point-max)))
               (eq (get-text-property (point) 'face) 'eshell-autosuggest-overlay-face))
      (delete-char 1))))

(defun eshell-autosuggest-overlay--post-command ()
  "Search for a suggestion in history and display it."
  (when (equal (point) (point-max))
    (let* ((begin-cmd (save-excursion
                        (eshell-bol)
                        (point)))
           (end-cmd (point))
           (prefix (buffer-substring-no-properties begin-cmd end-cmd)))
      (when (not (string-blank-p prefix))
        (when-let (candidate (eshell-autosuggest-overlay--candidate prefix))
          (let ((suggestion (substring candidate (length prefix))))
            (when (not (string-blank-p suggestion))
              (setq eshell-autosuggest-overlay--current-suggestion (substring-no-properties suggestion))
              (eshell-autosuggest-overlay--display-ov))))))))

;;;###autoload
(define-minor-mode eshell-autosuggest-overlay-mode
  "Enable fish-like autosuggestions in eshell."
  :group 'eshell-autosuggest-overlay
  (if eshell-autosuggest-overlay-mode
      (progn (add-hook 'post-command-hook #'eshell-autosuggest-overlay--post-command nil 'local)
             (add-hook 'pre-command-hook #'eshell-autosuggest-overlay--pre-command nil 'local))
    (remove-hook 'post-command-hook #'eshell-autosuggest-overlay--post-command 'local)
    (remove-hook 'pre-command-hook #'eshell-autosuggest-overlay--pre-command 'local)))

(provide 'eshell-autosuggest-overlay)

;;; eshell-autosuggest-overlay.el ends here
