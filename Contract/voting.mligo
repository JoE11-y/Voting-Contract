// Initialising the variables
type initParameter = string list * int
type voteParameter = string
type winner_dets = { winner : string ; votes : int }
type candidateMap = (string, int) map

type entryPoints = 
| Init of initParameter
| Vote of voteParameter
| GetWinner

// Defining the storage
type storage = {
    admin: address ;
    candidates : (string, int) map ;
    voting_end_time : timestamp ;
    voters : (address, bool) map ;
    winner_details : winner_dets ;
}

type returnType = operation list * storage

// First Entrypoint
let init(params, store : initParameter * storage) : returnType =
    // Check if currrent account was admin
    if Tezos.source <> store.admin
    then
        (failwith "Admin not recognized" : returnType)
    else
       let (candidate_names, voting_time_days) = params in
       // Iterate through list of names supplied by admin and add them to the mapping with an initial value of 0 votes, also initialise the voters map 
       // then store them in storage
       let addToMap (candidates_Mapping, name : candidateMap * string ) : (string, int) map = Map.add name 0 candidates_Mapping in
       let new_candidates : (string, int) map = List.fold_left addToMap store.candidates candidate_names in
       let voting_end_time = Tezos.now + voting_time_days in
       let store = {store with candidates = new_candidates ; voting_end_time = voting_end_time ; voters = (Map.empty : (address, bool) map) ; } in
    (([] : operation list), store)

// Second Entrypoint
let vote(name, store : voteParameter * storage) : returnType =
    // check if voting time has ended
    if Tezos.now > store.voting_end_time
    then
        (failwith "Voting has Ended" : returnType)
    else
        // check if voter has paid voting fee
        if Tezos.amount < 0.5tz 
        then
            (failwith "You need a minimum of 0.5tezos to vote" : returnType)
        else
            // keep record of the voters address
            let addr : address = Tezos.source in

            // check if name supplied by voter exists in the candidates record
            let candidate_exists : bool =
                match Map.find_opt name store.candidates with
                | Some (i) -> true
                | None -> false
            in

            // if it exists
            if candidate_exists 
            then
                // check if the voter himself has not already voted on the platform
                let hasVoted : bool = 
                    match Map.find_opt addr store.voters with
                    | Some x -> x
                    | None -> false
                in
                if(hasVoted)
                then
                    (failwith "Voter has already voted" : returnType)
                else
                    // if he has not voted, update his status to become true
                    let updated_voters : (address, bool) map = 
                        Map.add addr True store.voters 
                    in
                    
                    // get the number of votes for the candidate 
                    let votes : int =
                        match Map.find_opt name store.candidates with
                        | Some k -> k
                        | None -> (failwith "No vote count for this candidate" : int)
                    in
                    
                    // add 1 to the votes
                    let updateVotes : int = votes + 1 in

                    // update the mapping of the candidates and store back in the storage
                    let updated_candidate_votes = Map.update
                        name
                        (Some updateVotes)
                        store.candidates
                    in
                    let store = {store with candidates = updated_candidate_votes ; voters = updated_voters ; } in
                (([] : operation list), store)
            else
                (failwith "Candidate name does not exist" : returnType)

// Third Entrypoint
let get_winner (store : storage) : returnType =
    // check if voting time has not ended
    if Tezos.now < store.voting_end_time 
    then
        (failwith "Voting session has not ended" : returnType)
    else    
        // check if source is admin
        if Tezos.source <> store.admin
        then
            (failwith "Admin not recognized" : returnType)
        else
            // now we iterate through the candidates mapping to extract the candidate with the highest number of votes
            let checkVotes (i, j : winner_dets * (string * int)) : winner_dets =
                if i.votes > j.1
                then
                    i
                else
                    {winner = j.0 ; votes = j.1}
            in

            // this is actually the entrance point for checking for the highest votes, then we return a record, containing the name of the candidate
            // and the number of votes he has gotten, then store in storage.
            let winner_details : winner_dets = 
                Map.fold checkVotes store.candidates {winner = " " ; votes = 0} 
            in
            
            let store = {store with winner_details = winner_details ; } in

        (([] : operation list), store)

let main (action, store : entryPoints * storage) : returnType =
    match action with 
    | Init params -> init(params, store)
    | Vote param -> vote (param, store)
    | GetWinner -> get_winner store
