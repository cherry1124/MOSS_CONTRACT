# Smart Contract-based Secure Spectrum Sharing in Multi-Operators Wireless Communication Networks
## The system model
Dynamic spectrum sharing is a promising way to solve the spectrum underutilization of multi-operators. Underloaded operators(OP) who may have the idle spectrum can join the seller OPs group and share their idle spectrum with a certain price. Overloaded Ops, whose licensed spectrum is unable to meet needs of all users, can join the buyer OPs group to purchase the spectrum from the seller OPs group. 
We design a Multi-OPs Spectrum Sharing (MOSS) smart contract on the consortium blockchain for spectrum sharing in wireless communication networks. Without a trustless spectrum broker, different OPs can autonomously trade the spectrum by calling functions defined in the MOSS smart contract. 
![](fig1.png)
## How to implement the MOSS?
You can test our MOSS smart contract using Remix IDE. Go to [RemixIDE](https://remix.ethereum.org "RemixIDE") and upload our code file MOSS.sol.
## Function introduction
##### 1. The government deploys the smart contract
In Remix-IDE select the account of government and click on *Deploy*.
##### 2. OPs submit the bid:
Call the function BidOrAskSubmit() from account of OPs with the following arguments:

<code> _role:xxx, _amount:xxx, _price:xxx </code>

##### 3. OPs judge whether the registration stage is ended:
Call the function RegistrationEnd( ) from account of OPs.

##### 4.The government open the spectrum auction of registered OPs:
Call the function sortAskByIncrease(),sortBidByDecrease(),DoubleAuction() orderly from account of government.

##### 5.The government open the free-trading market among unsuccessfully matched OPs:
Call the function freeTradeBegin() from account of government. 

<code>  _freeMarketTime:xxx </code>
##### 6.Seller OPs can change the bid price or amount and buyer OPs can submit the newly wanted bid:
Call the function orderResponse() from account of OPs with the following arguments:

<code> _releaseOrresponse:xxx,  _op:xxx, _role:xxx,  _price:xxx, _amount；xxx</code>

##### 7. OPs can judge whether the free-trading market is ended:
Call the function MarketEnd() from account of OPs.

##### 8. The government can superwise whether OPs have exchange the spectrum usage right correctly:
Call the function payORnot() from account of government with the following arguments:

<code> _op:xxx,violateOrnot:xxx</code>

##### 8. OPs can withdraw the remained deposit:
Call the function withdraw() from account of OPs.
