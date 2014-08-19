if [ -z "$DOKKU_CONTROLLER" ]
then
	function dokku {
	if [ "$1" = "create" ]
	then
		appname=$(echo "print(elfs.GenName())" | lua -l elfs)
		if git remote add dokku dokku@$DOKKU_CONTROLLER:$appname
		then
			echo "-----> Dokku remote added at $DOKKU_CONTROLLER"
			echo "-----> Application name is $appname"
		else
			echo "!      Dokku remote not added! Do you already have a dokku remote?"
			return
		fi
		git push dokku master
	else
		appname=$(git remote -v 2>/dev/null | grep dokku | head -n 1 | cut -f1 -d' ' | cut -f2 -d':' 2>/dev/null)
		if [ "$?" != "0" ]
		then
			ssh dokku@$DOKKU_CONTROLLER $*
			exit
		fi
		verb=$1
		shift
		ssh dokku@$DOKKU_CONTROLLER "$verb" "$appname" $@
	fi
}
fi
