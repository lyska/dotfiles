;;; ob-lua.el --- org-babel functions for lua evaluation

;; Copyright (C) 2009-2014 Free Software Foundation, Inc.

;; Authors: Eric Schulte
;;	 Dan Davison
;; Keywords: literate programming, reproducible research
;; Homepage: http://orgmode.org

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for evaluating lua source code.

;;; Code:
(require 'ob)
(eval-when-compile (require 'cl))

(declare-function org-remove-indentation "org" )
(declare-function lua-shell "ext:lua-mode" (&optional argprompt))
(declare-function lua-toggle-shells "ext:lua-mode" (arg))
(declare-function run-lua "ext:lua" (cmd &optional dedicated show))

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("lua" . "lua"))

(defvar org-babel-default-header-args:lua '())

(defcustom org-babel-lua-command "lua"
  "Name of the command for executing Lua code."
  :version "24.4"
  :package-version '(Org . "8.0")
  :group 'org-babel
  :type 'string)

(defcustom org-babel-lua-mode
  (if (or (featurep 'xemacs) (featurep 'lua-mode)) 'lua-mode 'lua)
  "Preferred lua mode for use in running lua interactively.
This will typically be either 'lua or 'lua-mode."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'symbol)

(defvar org-src-preserve-indentation)

(defcustom org-babel-lua-hline-to "None"
  "Replace hlines in incoming tables with this when translating to lua."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'string)

(defcustom org-babel-lua-None-to 'hline
  "Replace 'None' in lua tables with this before returning."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'symbol)

(defun org-babel-execute:lua (body params)
  "Execute a block of Lua code with Babel.
This function is called by `org-babel-execute-src-block'."
  (let* ((session (org-babel-lua-initiate-session
		   (cdr (assoc :session params))))
         (result-params (cdr (assoc :result-params params)))
         (result-type (cdr (assoc :result-type params)))
	 (return-val (when (and (eq result-type 'value) (not session))
		       (cdr (assoc :return params))))
	 (preamble (cdr (assoc :preamble params)))
         (full-body
	  (org-babel-expand-body:generic
	   (concat body (if return-val (format "\nreturn %s" return-val) ""))
	   params (org-babel-variable-assignments:lua params)))
         (result (org-babel-lua-evaluate
		  session full-body result-type result-params preamble)))
    (org-babel-reassemble-table
     result
     (org-babel-pick-name (cdr (assoc :colname-names params))
			  (cdr (assoc :colnames params)))
     (org-babel-pick-name (cdr (assoc :rowname-names params))
			  (cdr (assoc :rownames params))))))

(defun org-babel-prep-session:lua (session params)
  "Prepare SESSION according to the header arguments in PARAMS.
VARS contains resolved variable references"
  (let* ((session (org-babel-lua-initiate-session session))
	 (var-lines
	  (org-babel-variable-assignments:lua params)))
    (org-babel-comint-in-buffer session
      (mapc (lambda (var)
              (end-of-line 1) (insert var) (comint-send-input)
              (org-babel-comint-wait-for-output session)) var-lines))
    session))

(defun org-babel-load-session:lua (session body params)
  "Load BODY into SESSION."
  (save-window-excursion
    (let ((buffer (org-babel-prep-session:lua session params)))
      (with-current-buffer buffer
        (goto-char (process-mark (get-buffer-process (current-buffer))))
        (insert (org-babel-chomp body)))
      buffer)))

;; helper functions

(defun org-babel-variable-assignments:lua (params)
  "Return a list of Lua statements assigning the block's variables."
  (mapcar
   (lambda (pair)
     (format "%s=%s"
	     (car pair)
	     (org-babel-lua-var-to-lua (cdr pair))))
   (mapcar #'cdr (org-babel-get-header params :var))))

(defun org-babel-lua-var-to-lua (var)
  "Convert an elisp value to a lua variable.
Convert an elisp value, VAR, into a string of lua source code
specifying a variable of the same value."
  (if (listp var)
      (if (and (= 1 (length var)) (not (listp (car var))))
          (org-babel-lua-var-to-lua (car var))
        (if (and
             (= 2 (length var))
             (not (listp (car var))))
            (concat
             (substring-no-properties (car var))
             "="
             (org-babel-lua-var-to-lua (cdr var)))
          (concat "{" (mapconcat #'org-babel-lua-var-to-lua var ", ") "}")))
    (if (equal var 'hline)
        org-babel-lua-hline-to
      (format
       (if (and (stringp var) (string-match "[\n\r]" var)) "\"\"%S\"\"" "%S")
       (if (stringp var) (substring-no-properties var) var)))))

(defun org-babel-lua-table-or-string (results)
  "Convert RESULTS into an appropriate elisp value.
If the results look like a list or tuple, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  (let ((res (org-babel-script-escape results)))
    (if (listp res)
        (mapcar (lambda (el) (if (equal el 'None)
                            org-babel-lua-None-to el))
                res)
      res)))

(defvar org-babel-lua-buffers '((:default . "*Lua*")))

(defun org-babel-lua-session-buffer (session)
  "Return the buffer associated with SESSION."
  (cdr (assoc session org-babel-lua-buffers)))

(defun org-babel-lua-with-earmuffs (session)
  (let ((name (if (stringp session) session (format "%s" session))))
    (if (and (string= "*" (substring name 0 1))
	     (string= "*" (substring name (- (length name) 1))))
	name
      (format "*%s*" name))))

(defun org-babel-lua-without-earmuffs (session)
  (let ((name (if (stringp session) session (format "%s" session))))
    (if (and (string= "*" (substring name 0 1))
	     (string= "*" (substring name (- (length name) 1))))
	(substring name 1 (- (length name) 1))
      name)))

(defvar lua-default-interpreter)
(defvar lua-which-bufname)
(defvar lua-shell-buffer-name)
(defun org-babel-lua-initiate-session-by-key (&optional session)
  "Initiate a lua session.
If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session."
  (require org-babel-lua-mode)
  (save-window-excursion
    (let* ((session (if session (intern session) :default))
           (lua-buffer (org-babel-lua-session-buffer session))
	   (cmd (if (member system-type '(cygwin windows-nt ms-dos))
		    (concat org-babel-lua-command " -i")
		  org-babel-lua-command)))
      (cond
       ((and (eq 'lua org-babel-lua-mode)
	     (fboundp 'run-lua)) ; lua.el
	(if (not (version< "24.1" emacs-version))
	    (run-lua cmd)
	  (unless lua-buffer
	    (setq lua-buffer (org-babel-lua-with-earmuffs session)))
	  (let ((lua-shell-buffer-name
		 (org-babel-lua-without-earmuffs lua-buffer)))
	    (run-lua cmd))))
       ((and (eq 'lua-mode org-babel-lua-mode)
	     (fboundp 'lua-shell)) ; lua-mode.el
	;; Make sure that lua-which-bufname is initialized, as otherwise
	;; it will be overwritten the first time a Lua buffer is
	;; created.
	(lua-toggle-shells lua-default-interpreter)
	;; `lua-shell' creates a buffer whose name is the value of
	;; `lua-which-bufname' with '*'s at the beginning and end
	(let* ((bufname (if (and lua-buffer (buffer-live-p lua-buffer))
			    (replace-regexp-in-string ;; zap surrounding *
			     "^\\*\\([^*]+\\)\\*$" "\\1" lua-buffer)
			  (concat "Lua-" (symbol-name session))))
	       (lua-which-bufname bufname))
	  (lua-shell)
	  (setq lua-buffer (org-babel-lua-with-earmuffs bufname))))
       (t
	(error "No function available for running an inferior Lua")))
      (setq org-babel-lua-buffers
	    (cons (cons session lua-buffer)
		  (assq-delete-all session org-babel-lua-buffers)))
      session)))

(defun org-babel-lua-initiate-session (&optional session params)
  "Create a session named SESSION according to PARAMS."
  (unless (string= session "none")
    (org-babel-lua-session-buffer
     (org-babel-lua-initiate-session-by-key session))))

(defvar org-babel-lua-eoe-indicator "'org_babel_lua_eoe'"
  "A string to indicate that evaluation has completed.")
(defvar org-babel-lua-wrapper-method
  "
function main()
%s
end

fd=io.open(\"%s\", \"w\")
fd:write( main() )
fd:close()")
(defvar org-babel-lua-pp-wrapper-method
  "
-- table to string
function t2s(t, indent)
   if indent == nil then
      indent = \"\"
   end
   if type(t) == \"table\" then
      ts = \"\"
      for k,v in pairs(t) do
         if type(v) == \"table\" then
            ts = ts .. indent .. t2s(k,indent .. \"  \") .. \" = \\n\" ..
               t2s(v, indent .. \"  \")
         else
            ts = ts .. indent .. t2s(k,indent .. \"  \") .. \" = \" ..
               t2s(v, indent .. \"  \") .. \"\\n\"
         end
      end
      return ts
   else
      return tostring(t)
   end
end


function main()
%s
end

fd=io.open(\"%s\", \"w\")
fd:write(t2s(main()))
fd:close()")

(defun org-babel-lua-evaluate
  (session body &optional result-type result-params preamble)
  "Evaluate BODY as Lua code."
  (if session
      (org-babel-lua-evaluate-session
       session body result-type result-params)
    (org-babel-lua-evaluate-external-process
     body result-type result-params preamble)))

(defun org-babel-lua-evaluate-external-process
  (body &optional result-type result-params preamble)
  "Evaluate BODY in external lua process.
If RESULT-TYPE equals 'output then return standard output as a
string.  If RESULT-TYPE equals 'value then return the value of the
last statement in BODY, as elisp."
  (let ((raw
         (case result-type
           (output (org-babel-eval org-babel-lua-command
                                   (concat (if preamble (concat preamble "\n"))
                                           body)))
           (value (let ((tmp-file (org-babel-temp-file "lua-")))
                    (org-babel-eval
                     org-babel-lua-command
                     (concat
                      (if preamble (concat preamble "\n") "")
                      (format
                       (if (member "pp" result-params)
                           org-babel-lua-pp-wrapper-method
                         org-babel-lua-wrapper-method)
                       (mapconcat
                        (lambda (line) (format "\t%s" line))
                        (split-string
                         (org-remove-indentation
                          (org-babel-trim body))
                         "[\r\n]") "\n")
                       (org-babel-process-file-name tmp-file 'noquote))))
                    (org-babel-eval-read-file tmp-file))))))
    (org-babel-result-cond result-params
      raw
      (org-babel-lua-table-or-string (org-babel-trim raw)))))

(defun org-babel-lua-evaluate-session
    (session body &optional result-type result-params)
  "Pass BODY to the Lua process in SESSION.
If RESULT-TYPE equals 'output then return standard output as a
string.  If RESULT-TYPE equals 'value then return the value of the
last statement in BODY, as elisp."
  (let* ((send-wait (lambda () (comint-send-input nil t) (sleep-for 0 5)))
	 (dump-last-value
	  (lambda
	    (tmp-file pp)
	    (mapc
	     (lambda (statement) (insert statement) (funcall send-wait))
	     (if pp
		 (list
		  "import pprint"
		  (format "open('%s', 'w').write(pprint.pformat(_))"
			  (org-babel-process-file-name tmp-file 'noquote)))
	       (list (format "open('%s', 'w').write(str(_))"
			     (org-babel-process-file-name tmp-file
                                                          'noquote)))))))
	 (input-body (lambda (body)
		       (mapc (lambda (line) (insert line) (funcall send-wait))
			     (split-string body "[\r\n]"))
		       (funcall send-wait)))
         (results
          (case result-type
            (output
             (mapconcat
              #'org-babel-trim
              (butlast
               (org-babel-comint-with-output
                   (session org-babel-lua-eoe-indicator t body)
                 (funcall input-body body)
                 (funcall send-wait) (funcall send-wait)
                 (insert org-babel-lua-eoe-indicator)
                 (funcall send-wait))
               2) "\n"))
            (value
             (let ((tmp-file (org-babel-temp-file "lua-")))
               (org-babel-comint-with-output
                   (session org-babel-lua-eoe-indicator nil body)
                 (let ((comint-process-echoes nil))
                   (funcall input-body body)
                   (funcall dump-last-value tmp-file
                            (member "pp" result-params))
                   (funcall send-wait) (funcall send-wait)
                   (insert org-babel-lua-eoe-indicator)
                   (funcall send-wait)))
               (org-babel-eval-read-file tmp-file))))))
    (unless (string= (substring org-babel-lua-eoe-indicator 1 -1) results)
      (org-babel-result-cond result-params
	results
        (org-babel-lua-table-or-string results)))))

(defun org-babel-lua-read-string (string)
  "Strip 's from around Lua string."
  (if (string-match "^'\\([^\000]+\\)'$" string)
      (match-string 1 string)
    string))

(provide 'ob-lua)

;;; ob-lua.el ends here
