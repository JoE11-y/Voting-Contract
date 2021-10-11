type initParameter = string list
type voteParameter = string

type candidateMap = (string, int) map

type entryPoints = 
| Init of initParameter
| Vote of voteParameter

type storage = {
    admin: address ;
    candidates : (string, int) map ;
    voters : (address, bool) map ;
}

type returnType = operation list * storage

let init_candidates(candidate_names, store : string list * storage) : returnType =
    if Tezos.source <> store.admin
    then
        (failwith "Admin not recognized" : returnType)
    else
       let addToMap (_param, name : candidateMap * string ) : (string, int) map = Map.add name 0 store.candidates in
       let new_candidates : (string, int) map = List.fold_left addToMap store.candidates candidate_names in
       let store = {store with candidates = new_candidates ; voters = (Map.empty : (address, bool) map) ; } in
    (([] : operation list), store)

let vote(name, store : voteParameter * storage) : returnType =
    if Tezos.amount < 0.5tz 
    then
        (failwith "You need a minimum of 0.5tezos to vote" : returnType)
    else
        let addr : address = Tezos.source in

        let candidate_exists : bool =
            match Map.find_opt name store.candidates with
            | Some (i) -> true
            | None -> false
        in

        if candidate_exists 
        then
            let hasVoted : bool = 
                match Map.find_opt addr store.voters with
                | Some x -> x
                | None -> false
            in
            if(hasVoted)
            then
                (failwith "Voter has already voted" : returnType)
            else
                let updated_voters : (address, bool) map = 
                    Map.add addr True store.voters 
                in

                let votes : int =
                    match Map.find_opt name store.candidates with
                    | Some k -> k
                    | None -> (failwith "No vote count for this candidate" : int)
                in

                let updateVotes : int = votes + 1 in

                let updated_candidate_votes = Map.update
                    name
                    (Some updateVotes)
                    store.candidates
                in
                let store = {store with candidates = updated_candidate_votes ; voters = updated_voters ; } in
            (([] : operation list), store)
        else
            (failwith "Candidate name does not exist" : returnType)
    

let main (action, store : entryPoints * storage) : returnType =
    match action with 
    | Init param -> init_candidates (param, store)
    | Vote param -> vote (param, store)
