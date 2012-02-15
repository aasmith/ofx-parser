== ofx-parser
by Andrew A. Smith

http://ofx-parser.rubyforge.org/
http://rubyforge.org/projects/ofx-parser/

== DESCRIPTION:

ofx-parser is a ruby library to parse a realistic subset of the lengthy OFX 1.x specification.

== FEATURES/PROBLEMS:

* Reads OFX responses - i.e. those downloaded from financial institutions and
  puts it into a usable object graph.
* Supports the 3 main message sets: banking, credit card and investment
  accounts, as well as the required 'sign on' set.
* Knows about SIC codes - if your institution provides them.
  See http://www.eeoc.gov/stats/jobpat/siccodes.html
* Monetary amounts can be retrieved either as a raw string, or in pennies.
* Supports OFX timestamps.

== SYNOPSIS:

Supports bank accounts:

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

Also supports credit cards...

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

Working on investment accounts...

== REQUIREMENTS:

* hpricot >= 0.6

== INSTALL:

* gem install ofx-parser

== LICENSE:

Copyright (c) 2007, Andrew A. Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright owner nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
