#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=number_guess --no-align --tuples-only -c"
# sudo service postgresql start

RANDOM_NUM=$(( RANDOM % 1000 + 1 ))
while true
do
    echo "Enter your username:"
    read USERNAME

    if [[ ${#USERNAME} -le 22 ]]; then
        break
    else
        echo "Username must be 22 characters or less."
    fi
done

USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';" | sed 's/ //g')



if [[ -z $USER_INFO ]]
then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    
    INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL);")
else
   
    echo "$USER_INFO" | while IFS="|" read GAMES_PLAYED BEST_GAME
    do
      echo "Welcome back, $USERNAME! You have played $(echo $GAMES_PLAYED | xargs) games, and your best game took $(echo $BEST_GAME | xargs) guesses."
    done
fi


echo "Guess the secret number between 1 and 1000:"


NUMBER_OF_GUESSES=0

while true
do
    read TAKE_GUESS

    if ! [[ $TAKE_GUESS =~ ^[0-9]+$ ]]
    then
        echo "That is not an integer, guess again:"
        continue
    fi

    ((NUMBER_OF_GUESSES++))

    if [[ $TAKE_GUESS -gt $RANDOM_NUM ]]
    then
        echo "It's lower than that, guess again:"
    elif [[ $TAKE_GUESS -lt $RANDOM_NUM ]]
    then
        echo "It's higher than that, guess again:"
    else
        echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUM. Nice job!"

        CURRENT_STATS=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")
        IFS="|" read GAMES_PLAYED BEST_GAME <<< "$CURRENT_STATS"
        NEW_GAMES_PLAYED=$(( $(echo $GAMES_PLAYED | xargs) + 1 ))

        BEST_GAME_TRIMMED=$(echo $BEST_GAME | xargs)

        if [[ -z $BEST_GAME_TRIMMED || $NUMBER_OF_GUESSES -lt $BEST_GAME_TRIMMED ]]
        then
           UPDATE_RES=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME';")
        else
            UPDATE_RES=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE username='$USERNAME';")
        fi
        break
    fi
done



