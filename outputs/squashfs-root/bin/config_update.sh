#!/bin/sh


get_line_num()
{
        arg_field=$(echo $2 | cut -d "=" -f 1)
        arg_field_line_num=$(grep -n "^$arg_name=" $CONFIG_FILE | cut -d ":" -f1 )
        if [ -z "$arg_field_line_num" ]; then
                #echo -e "add: \"$arg_name\": can not find argument field, added it"
                return 0
        else
                #echo "matched argument field in line:  $arg_name_line_num"
                return $arg_field_line_num
        fi

}

if [ $# -lt 2 ]; then
        echo "Usage: $0 <config parameter> <config file>"
        exit 254
else
        CONFIG_FILE=$1
        [ ! -f $CONFIG_FILE ] && touch $CONFIG_FILE
        while [ "$2" ]; do
                # Check if argument name and argument value exist
                arg_name=$(echo $2 | cut -d "=" -f 1)
                arg_value=$(echo $2 | cut -d "=" -f 2)
                if [ -z "$arg_name" -o -z "$arg_value" ]; then
                        echo -e "error: \"$1\": argument has no name or value around \"=\""
                        exit 255
                fi

                # Get the line number of the argument from CONFIG_FILE
                get_line_num $arg_name $CONFIG_FILE
                args_line_num=$?

                if [ $args_line_num == 0 ];then
                        echo $2 >> $CONFIG_FILE
                else
                        # use sed change the argument line
                        sed -i "${args_line_num}c $arg_name=$arg_value" $CONFIG_FILE
                        new_line=$(sed -n "${args_line_num}p" $CONFIG_FILE)
                        shift 1
                fi
        done
	sync
fi
