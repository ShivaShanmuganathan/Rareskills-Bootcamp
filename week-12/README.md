# Week 11-12: Re-entrancy

Assignments:

- Write a simple Amm.
    - It can support just **exactIn**, just **exactOut**, or both
    - Fees and liquidity provision are not necessary, just assume that the contract has tokens given to it by charity :-)
    - If you choose to go with the pool vs pair architecture as discussed in the lesson, make sure you either:
        - add a system-wide re-entrancy lock
            - or
        - do not support re-entrancy tokens (eg 777)
    - Bonus: fuzz it in Woke
- Read Chapter 2 of Automated Market Makers.