(defun efs/run-in-background (command)
   (let ((command-parts (split-string command "[ ]+")))
     (apply #'call-process `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))

 (defun efs/set-wallpaper ()
   (interactive)
   (start-process-shell-command
      "feh" nil "feh --bg-scale ~/.local/share/backgrounds/Abstract-Nord.png"))

 (defun efs/exwm-init-hook ()
   ;; Make workspace 1 be the one where we land at startup
   (exwm-workspace-switch-create 1)

   ;; Open eshell by default
   (eshell)

   ;(display-battery-mode 1)

   (setq display-time-day-and-date t)
   (display-time-mode 1)

   ;; Start the Polybar panel
   (efs/start-panel)

   ;; Launch apps that will run in the background
   (efs/run-in-background "dunst")
   (efs/run-in-background "nm-applet")
   (efs/run-in-background "pasystray")
   (efs/run-in-background "blueman-applet"))

 (defun efs/exwm-update-class ()
    (exwm-workspace-rename-buffer exwm-class-name))

 (defun efs/exwm-update-title ()
   (pcase exwm-class-name
     ("Nyxt" (exwm-workspace-rename-buffer (format "Nyxt: %s" exwm-title)))))

 (defun efs/configure-window-by-class ()
   (interactive)
   (pcase exwm-class-name
     ("Nyxt" (exwm-workspace-move-window 2))))

 (use-package exwm
    :config
    ;; Set the default number of workspaces
    (setq exwm-workspace-number 5)

    ;; When window "class" updates, use it to set the buffer name
    (add-hook 'exwm-update-class-hook #'efs/exwm-update-class)

    ;; When window title updates, use it to set the buffer name
    (add-hook 'exwm-update-title-hook #'efs/exwm-update-title)

    ;; Configure windows as they're created
    (add-hook 'exwm-manage-finish-hook #'efs/configure-window-by-class)

    ;; When exwm starts, do extra configuration
    (add-hook 'exwm-init-hook #'efs/exwm-init-hook)

    ;; Rebind Caps lock to Ctrl 
    (start-process-shell-command "xmodmap" nil "xmodmap ~/.emacs.d/exwm/Xmodmap")

    (require 'exwm-randr)
    (exwm-randr-enable)
    (start-process-shell-command "xrandr" nil "xrandr --output VGA-1 --off --output DVI-D-1 --off --output HDM-1 --mode 1920x1200 --pos 0x0 --rotate normal")

    ;; Set wallpaper after changing the resolution
    (efs/set-wallpaper)

    ;(require 'exwm-systemtray)
    ;(setq exwm-systemtray-height 32)
    ;(exwm-systemtray-enable)

    (setq exwm-workspace-warp-cursor t)

    (setq mouse-autoselect-window t
          focus-follows-mouse t)

    (setq exwm-input-prefix-keys
      '(?\C-x
        ?\C-u  
        ?\C-h
        ?\M-x
        ?\M-`
        ?\M-&
        ?\M-:
        ?\C-\M-j ;; Buffer list
        ?\C-\ )) ;; Ctrl + Space

    ;; Ctrl+Q will enable the next key to be sent directly
    (define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)

    ;; Set up global keybindings. These always work, no matter the inpuy state
    ;; Keep in mind that changing this list after EXWM initializes has no effect

    (setq exwm-input-global-keys
      `( ;; Reset to line-mode (C-c C-k switches to char-mode via exwm-input-release-keyboard)
         ([?\s-r] . exwm-reset)

         ;; Move between windows
         ([s-left] . windmove-left)
         ([s-right] . windmove-right)
         ([s-up] . windmove-up)
         ([s-down] . windmove-down)

         ;; Launch apps via shell command
         ([?\s-&] . (lambda (command)
                      (interactive (list (read-shell-command "$ ")))
                      (start-process-shell-command command nil command)))

         ;; Switch workplace
         ([?\s-w] . exwm-workspace-switch)
         ([?\s-`] . (lambda () (interactive) (exwm-workspace-switch-create 0)))

         ;; 's-N': Switch to certain workspace with Super plus a number key
         ,@(mapcar (lambda (i)
                     `(,(kbd (format "s-%d" i)) .
                       (lambda ()
                         (interactive)
                         (exwm-workspace-switch-create ,i))))
                   (number-sequence 0 9))))

(exwm-input-set-key (kbd "s-SPC") 'counsel-linux-app)

(exwm-enable))

(defun efs/org-babel-tangle-config ()
  (when (string-equal (file-name-directory (buffer-file-name))
		      (expand-file-name user-emacs-directory))
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

;; Make sure the server is started (better to do this in your main emacs config!)
(server-start)

(defvar efs/polybar-process nil
  "Holds the process of the running Polybar instance, if any")

(defun efs/kill-panel ()
  (interactive)
  (when efs/polybar-process
    (ignore-errors
      (kill-process efs/polybar-process)))
    (setq efs/polybar-process nil))

(defun efs/start-panel ()
  (interactive)
  (efs/kill-panel)
  (setq efs/polybar-process (start-process-shell-command "polybar" nil "polybar panel")))

(defun efs/send-polybar-hook (module-name hook-index)
  (start-process-shell-command "polybar-msg" nil (format "polybar-msg hook %s %s" module-name hook-index)))

(defun efs/send-polybar-exwm-workspace ()
  (efs/send-polybar-hook "exwm-workspace" 1))

(add-hook 'exwm-workspace-switch-hook #'efs/send-polybar-exwm-workspace)
