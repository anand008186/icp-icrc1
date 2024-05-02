import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import IcrcToken "./icrc1.mo";

actor {

type UserBalance = HashMap.HashMap<Principal, Nat>;

var userBalances : UserBalance = HashMap.HashMap<Principal, Nat>(5, Principal.equal, Principal.hash);

public shared(msg) func deposit(amount: Nat) : async Bool {
    await transfer_from(msg.caller,Principal.fromActor(this), amount);
    
        userBalances.put(msg.caller, amount);
   
};

public shared(msg) func transfer(amount: Nat) : async Bool {
    let _userBalance = userBalances.get(msg.caller);
    if (_userBalance>= amount) {
       await IcrcToken.transfer(msg.caller, amount);
        userBalances.put(msg.caller,_userBalance amount) ;
    } else {
       throw Error.reject("Insufficient balance");
    }
};

}