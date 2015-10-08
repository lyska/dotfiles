;; -*- mode: dotspacemacs -*-
(defun dotspacemacs/layers ()
  "Configuration Layers declaration."
  (setq-default
   dotspacemacs-configuration-layer-path '("~/code/dotfiles/spacemacs")
   dotspacemacs-configuration-layers
   '(auto-completion better-defaults
     (git :variables
          git-gutter-use-fringe t)
     markdown org syntax-checking go haskell
     erlang nim extra-langs themes-megapack colors
     ruby lua eirc dockerfile puppet yaml javascript
     python rust shell-scripts github perspectives
     cb-crontab xe-base xe-hoon xe-weechat xe-sr-speedbar
     xe-restclient)
   dotspacemacs-excluded-packages '()
   dotspacemacs-delete-orphan-packages t))

(defun dotspacemacs/init ()
  "Initialization function.
This function is called at the very startup of Spacemacs initialization
before layers configuration."
  (setq-default
   dotspacemacs-editing-style 'vim
   dotspacemacs-verbose-loading nil
   dotspacemacs-startup-banner nil
   dotspacemacs-always-show-changelog nil
   dotspacemacs-startup-lists '(recents projects)
   dotspacemacs-themes '(material
                         zenburn
                         solarized-light
                         solarized-dark
                         leuven)

   dotspacemacs-colorize-cursor-according-to-state t
   dotspacemacs-default-font '("Monoid"
                               :size 10
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)

   dotspacemacs-leader-key "SPC"
   dotspacemacs-emacs-leader-key "M-m"
   dotspacemacs-major-mode-leader-key ","
   dotspacemacs-major-mode-emacs-leader-key "C-M-m"
   dotspacemacs-command-key ":"
   dotspacemacs-enable-paste-micro-state t
   dotspacemacs-guide-key-delay 0.4
   dotspacemacs-loading-progress-bar t
   dotspacemacs-fullscreen-at-startup nil
   dotspacemacs-fullscreen-use-non-native nil
   dotspacemacs-maximized-at-startup nil
   dotspacemacs-active-transparency 90
   dotspacemacs-inactive-transparency 90
   dotspacemacs-mode-line-unicode-symbols t
   dotspacemacs-smooth-scrolling t
   dotspacemacs-smartparens-strict-mode nil
   dotspacemacs-persistent-server nil
   dotspacemacs-search-tools '("ag" "pt" "ack" "grep")
   dotspacemacs-default-package-repository nil
  )
  (add-to-list 'exec-path "~/.cabal/bin/")
  (add-to-list 'exec-path "~/go/bin")
  (add-to-list 'exec-path "~/bin/")
)

(defun dotspacemacs/config ()
  "Configuration function.
 This function is called at the very end of Spacemacs initialization after
layers configuration."
  ;;; All core config is done in the xe-base layer
)