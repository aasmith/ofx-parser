# ofx-parser
by Andrew A. Smith

http://ofx-parser.rubyforge.org/
http://rubyforge.org/projects/ofx-parser/

## DESCRIPTION:
ofx-parser is a ruby library to parse a realistic subset of the lengthy OFX 1.x specification.

## FEATURES/PROBLEMS:
* Reads OFX responses - i.e. those downloaded from financial institutions and
  puts it into a usable object graph.
* Supports the 3 main message sets: banking, credit card and investment
  accounts, as well as the required 'sign on' set.
* Knows about SIC codes - if your institution provides them.
  See http://www.eeoc.gov/stats/jobpat/siccodes.html
* Monetary amounts can be retrieved either as a raw string, or in pennies.
* Supports OFX timestamps.

## SYNOPSIS:
Supports bank accounts:

```ruby
require 'rubygems'
require 'ofx-parser'

ofx = OfxParser::OfxParser.parse(open("bank-statement.ofx"))
bank_acct = ofx.bank_accounts.first

bank_acct.number # => '103333333333'
bank_acct.routing_number # => '033000033'
bank_acct.balance # => '123.45'
bank_acct.balance_in_pennies # => 12345

bank_acct.statement.start_date # => DateTime
bank_acct.statement.end_date # => DateTime

bank_acct.statement.transactions.size # => 4

bank_acct.statement.transactions.first.payee # => "FOO, INC."
bank_acct.statement.transactions.first.type # => :DEBIT
bank_acct.statement.transactions.first.amount # => '-11.11'
bank_acct.statement.transactions.first.amount_in_pennies # => -1111
```

Also supports credit cards...
```ruby
ofx = OfxParser::OfxParser.parse(open("creditcard-statement.ofx"))
credit_card = ofx.credit_accounts.first

credit_card.remaining_credit # => '19000.0'
credit_card.remaining_credit_in_pennies # => '1900000'

credit_card.statement.start_date # => DateTime
credit_card.statement.end_date # => DateTime

credit_card.statement.transactions.size # => 10

credit_card.statement.transactions.first.type # => :DEBIT
credit_card.statement.transactions.first.amount # => '-19.17'
credit_card.statement.transactions.first.amount_in_pennies # => '-1917'
credit_card.statement.transactions.first.sic # => '7933'
credit_card.statement.transactions.first.sic_desc # => 'BOWLING CENTERS'
credit_card.statement.transactions.first.payee # => 'SUNSET BOWLING'
```

Working on investment accounts...

## REQUIREMENTS:

* hpricot >= 0.6

## INSTALL:

* gem install ofx-parser

## History
[History](History.md)

## Development
Clone the source, change into the source directory, install the required gems
and run the tests.
```sh
git clone git@github.com:cincinnatirb/ofx-parser.git
cd ofx-parser
bundle install
rake
```

## CONTRIBUTE:
1. [Fork][fork] the [official repository][repo].
1. [Create a topic branch.][branch]
1. Implement your feature or bug fix.
1. Add, commit, and push your changes.
1. [Submit a pull request.][pr]

[repo]: https://github.com/aasmith/ofx-parser/tree/master
[fork]: https://help.github.com/articles/fork-a-repo/
[branch]: https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/
[pr]: https://help.github.com/articles/using-pull-requests/

## LICENSE:
ofx-parser is Copyright © 2007 Andrew A. Smith. It is free
software, and may be redistributed under the terms specified in the
[LICENSE] file.