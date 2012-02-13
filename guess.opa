import stdlib.core.web.request

type game = {
    int number,
    int guess,
    int tries
}

type player = {string name, list(game) games}

database {
      stringmap(player) /user
}

function create_new_game() {
   {number:Random.int(99), guess:0, tries:10}
}

function get_or_create_player(name) {
    match(?/user[name]){
        case {none}:
            player = {~name, games:[create_new_game()]};
            /user[name] <- player; player
        case {some:player}: player;
    }
}

function update_game(name, g, guess) {
    (hint, g2) = if(guess > g.number) {
        ("too big", ({g with tries: g.tries-1}))
    } else if(guess < g.number) {
        ("too small", ({g with tries: g.tries-1}))
    } else {
        ("good job!", g)
    };

    /user[name]/games/hd <- g2
    line = <div>
            <div>Your guess: {guess}</div>
            <div>{hint}</div>
            <div>tries: {g2.tries}</div>
            <div>Answer: {g2.number}</div>
         </div>;
    line
}

@async server function check_guess() {
    int guess = String.to_int(Dom.get_value(#guess))
    cookie = get_cookie()
    g = List.head(get_or_create_player(cookie).games)
    html = update_game(cookie, g, guess)
    #game = html;
    Dom.clear_value(#guess)
}

function get_cookie() {
  string_of_user_id(match(HttpRequest.get_user()){case {~some}:some})
}

function start() {
  cookie = get_cookie()
  _ = get_or_create_player(cookie)
  <div id=#game ></div>
  <input id=#guess onnewline={function(_) { check_guess() }} />
  <input type="button" onclick={function(_) { check_guess() }} value="Guess" />
}

Server.start(Server.http, {title: "Guess the number", page: start })
