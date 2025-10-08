terminal=$(tty)

fixed_1=""
fixed_2=""
fixed_3=""
fixed_4=""
fixed_5=""

useless_letters=""
useable_letters=""

letter="water"
res_letter="AAAAA"

for j in $(seq 0 4); do
    echo "Checking letter $((j))" > "$terminal"

    echo "Hola" > "$terminal"

    letter=$(echo "$guess" | cut -c$((j + 1)))
    res_letter=$(echo "$result" | cut -c$((j + 1)))

    echo "Letter: $letter, Result letter: $res_letter" > "$terminal"

    case $res_letter in
        A) case $j in
                0) fixed_1="$letter" ;;
                1) fixed_2="$letter" ;;
                2) fixed_3="$letter" ;;
                3) fixed_4="$letter" ;;
                4) fixed_5="$letter" ;;
            esac
            ;;
        B) 
        # append the letter into useable_letters if not already there
                if ! echo "$useable_letters" | grep -q "$letter"; then
                    useable_letters="$useable_letters$letter"
                fi
            ;;
        X) # letter is not in the word
            # add letter to useless_letters if not already there
            if ! echo "$useless_letters" | grep -q "$letter"; then
                useless_letters="$useless_letters$letter"
            fi
            ;;
    esac
done

echo "Fixed letters: $fixed_1 $fixed_2 $fixed_3 $fixed_4 $fixed_5" > "$terminal"
echo "Useless letters: $useless_letters" > "$terminal"