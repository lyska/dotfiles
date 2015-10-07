;; sr-speedbar

;;; Commentary:
;;
;; The sr-speedbar.el was created just because I could not believe what I
;; read on http://www.emacswiki.org/cgi-bin/wiki/Speedbar.  They wrote there
;; that it is not possible to show the speedbar in the same frame.  But, as
;; we all know, ecb had this already.  So I started as some kind of joke :)
;; But when I found it useful and use it all the time.
;;
;; Now you type windows key with 's' (`s-s' in Emacs) will show the speedbar
;; in an extra window, same frame.  You can customize the initial width of the
;; speedbar window.
;;
;; Below are commands you can use:
;;
;; `sr-speedbar-open'                   Open `sr-speedbar' window.
;; `sr-speedbar-close'                  Close `sr-speedbar' window.
;; `sr-speedbar-toggle'                 Toggle `sr-speedbar' window.
;; `sr-speedbar-select-window'          Select `sr-speedbar' window.
;; `sr-speedbar-refresh-turn-on'        Turn on refresh speedbar content.
;; `sr-speedbar-refresh-turn-off'       Turn off refresh speedbar content.
;; `sr-speedbar-refresh-toggle'         Toggle refresh speedbar content.
;;
;; Enjoy! ;)
;;

(setq xe-sr-speedbar-packages
    '((sr-speedbar :location local)))

(defun xe-sr-speedbar/init-sr-speedbar ()
  (use-package sr-speedbar))
