require 'test/unit'
require 'ofx-parser'

class OfxParserTest < Test::Unit::TestCase

  OFX_FILES = {}

  fixtures_dir = File.dirname(__FILE__) + '/fixtures'

  # Load up the xml files
  Dir.open(fixtures_dir).each do |fn|
    next unless fn =~ /\.ofx\.sgml$/

    ofx = File.read(fixtures_dir + "/#{fn}")
    ofx.gsub!(/\r?\n/,"\r\n") # change line endings to \r\n

    OFX_FILES[fn.scan(/\w+/).first.to_sym] = ofx
  end

  def setup
    # empty ofx parser - useful for testing other methods independently
    @parser = OfxParser::OfxParser
  end

  def test_pre_process_strips_spaces
    header, body = @parser.pre_process(OFX_FILES[:with_spaces])

    assert_no_match(/>\s+.*?</, body, "should be no spaces after a tag close")
    assert_no_match(/>.*?\s+</, body, "should be no spaces before a tag close")
    assert_no_match(/>\s+</, body, "should be no spaces between two tags")
    assert_match("The user is authentic; operation succeeded.", body, "content in tags should not be altered")
  end

  def test_pre_process_header
    header, body = @parser.pre_process(OFX_FILES[:with_spaces])

    assert_equal 9, header.keys.size
  end

  def test_parse_datetime
    assert_equal DateTime.civil(2007, 6, 22, 19, 0, 0, Rational(-5,24)), @parser.parse_datetime('20070622190000.200[-5:CDT]')
    assert_equal DateTime.civil(2007, 6, 22, 19, 0, 0, Rational(9,24)), @parser.parse_datetime('20070622190000.200[+9.0:JST]')
    assert_equal DateTime.civil(2007, 6, 22), @parser.parse_datetime('20070622')
    assert_equal DateTime.civil(2007, 6, 22, 19, 0, 0), @parser.parse_datetime('20070622190000')
    assert_equal DateTime.civil(2007, 6, 22, 19, 0, 0), @parser.parse_datetime('20070622190000.200')
  end

  def test_sign_on
    ofx = OfxParser::OfxParser.parse(OFX_FILES[:with_spaces])

    assert_equal '0', ofx.sign_on.status.code
    assert_equal 'INFO', ofx.sign_on.status.severity
    assert_equal 'The user is authentic; operation succeeded.', ofx.sign_on.status.message
    assert_equal 'Success', ofx.sign_on.status.code_desc

    assert_equal DateTime.civil(2007,6,23,14,26,35,Rational(-5, 24)), ofx.sign_on.date
    assert_equal 'ENG', ofx.sign_on.language
    assert_equal 'U.S. Bank', ofx.sign_on.institute.name
    assert_equal '1402', ofx.sign_on.institute.id
  end

  def test_no_accounts
    ofx = OfxParser::OfxParser.parse(OFX_FILES[:with_spaces])

    assert_equal 0, ofx.accounts.size
  end

  def test_banking
    ofx = OfxParser::OfxParser.parse(OFX_FILES[:banking])

    acct = ofx.bank_accounts.first

    assert_equal '103333333333', acct.number
    assert_equal '033000033', acct.routing_number
    assert_equal :CHECKING, acct.type
    assert_equal '1234.09', acct.balance
    assert_equal 123409, acct.balance_in_pennies
    assert_equal DateTime.civil(2007,6,23,14,26,35,Rational(-5, 24)), acct.balance_date
    assert_equal '9C24229A0077EAA50000011353C9E00743FC', acct.transaction_uid

    statement = acct.statement

    assert_equal 'USD', statement.currency
    assert_equal DateTime.civil(2007,6,4,19,0,0,Rational(-5, 24)), statement.start_date
    assert_equal DateTime.civil(2007,6,22,19,0,0,Rational(-5, 24)), statement.end_date

    transactions = statement.transactions
    assert_equal 4, transactions.size

    assert_equal :PAYMENT, transactions[0].type
    assert_equal OfxParser::Transaction::TYPE[:PAYMENT], transactions[0].type_desc
    assert_equal DateTime.civil(2007,6,6,12,0,0), transactions[0].date
    assert_equal '-11.11', transactions[0].amount
    assert_equal -1111, transactions[0].amount_in_pennies
    assert_equal '11111111 22', transactions[0].fit_id
    assert_equal nil, transactions[0].check_number
    assert_equal nil, transactions[0].sic
    assert_equal nil, transactions[0].sic_desc
    assert_equal 'WEB AUTHORIZED PMT FOO INC', transactions[0].payee
    assert_equal 'Download from usbank.com. FOO INC', transactions[0].memo

    assert_equal :CHECK, transactions[1].type
    assert_equal OfxParser::Transaction::TYPE[:CHECK], transactions[1].type_desc
    assert_equal DateTime.civil(2007,6,7,12,0,0), transactions[1].date
    assert_equal '-111.11', transactions[1].amount
    assert_equal -11111, transactions[1].amount_in_pennies
    assert_equal '22222A', transactions[1].fit_id
    assert_equal '0000009611', transactions[1].check_number
    assert_equal nil, transactions[1].sic
    assert_equal nil, transactions[1].sic_desc
    assert_equal 'CHECK', transactions[1].payee
    assert_equal 'Download from usbank.com.', transactions[1].memo

    assert_equal :DIRECTDEP, transactions[2].type
    assert_equal OfxParser::Transaction::TYPE[:DIRECTDEP], transactions[2].type_desc
    assert_equal DateTime.civil(2007,6,14,12,0,0), transactions[2].date
    assert_equal '1111.11', transactions[2].amount
    assert_equal 111111, transactions[2].amount_in_pennies
    assert_equal 'X34AE33', transactions[2].fit_id
    assert_equal nil, transactions[2].check_number
    assert_equal nil, transactions[2].sic
    assert_equal nil, transactions[2].sic_desc
    assert_equal 'ELECTRONIC DEPOSIT BAR INC', transactions[2].payee
    assert_equal 'Download from usbank.com. BAR INC', transactions[2].memo

    assert_equal :CREDIT, transactions[3].type
    assert_equal OfxParser::Transaction::TYPE[:CREDIT], transactions[3].type_desc
    assert_equal DateTime.civil(2007,6,19,12,0,0), transactions[3].date
    assert_equal '11.11', transactions[3].amount
    assert_equal 1111, transactions[3].amount_in_pennies
    assert_equal '8 8 9089743', transactions[3].fit_id
    assert_equal nil, transactions[3].check_number
    assert_equal nil, transactions[3].sic
    assert_equal nil, transactions[3].sic_desc
    assert_equal 'ATM DEPOSIT US BANK ANYTOWNAS', transactions[3].payee
    assert_equal 'Download from usbank.com. US BANK ANYTOWN ASUS1', transactions[3].memo

    assert_equal 1, ofx.accounts.size
  end

  def test_multiple_bank_accounts
    ofx = OfxParser::OfxParser.parse(OFX_FILES[:banks])

    accts = ofx.bank_accounts
    assert_equal 2, ofx.accounts.size

    # Test Bank Account #1 ---------------------------------------------------

    acct = accts.first

    assert_equal '103333333333', acct.number
    assert_equal '033000033', acct.routing_number
    assert_equal :CHECKING, acct.type
    assert_equal '1234.09', acct.balance
    assert_equal 123409, acct.balance_in_pennies
    assert_equal DateTime.civil(2007,6,23,14,26,35,Rational(-5, 24)), acct.balance_date
    assert_equal '9C24229A0077EAA50000011353C9E00743FC', acct.transaction_uid

    statement = acct.statement

    assert_equal 'USD', statement.currency
    assert_equal DateTime.civil(2007,6,4,19,0,0,Rational(-5, 24)), statement.start_date
    assert_equal DateTime.civil(2007,6,22,19,0,0,Rational(-5, 24)), statement.end_date

    transactions = statement.transactions
    assert_equal 4, transactions.size

    assert_equal :PAYMENT, transactions[0].type
    assert_equal OfxParser::Transaction::TYPE[:PAYMENT], transactions[0].type_desc
    assert_equal DateTime.civil(2007,6,6,12,0,0), transactions[0].date
    assert_equal '-11.11', transactions[0].amount
    assert_equal -1111, transactions[0].amount_in_pennies
    assert_equal '11111111 22', transactions[0].fit_id
    assert_equal nil, transactions[0].check_number
    assert_equal nil, transactions[0].sic
    assert_equal nil, transactions[0].sic_desc
    assert_equal 'WEB AUTHORIZED PMT FOO INC', transactions[0].payee
    assert_equal 'Download from usbank.com. FOO INC', transactions[0].memo

    assert_equal :CHECK, transactions[1].type
    assert_equal OfxParser::Transaction::TYPE[:CHECK], transactions[1].type_desc
    assert_equal DateTime.civil(2007,6,7,12,0,0), transactions[1].date
    assert_equal '-111.11', transactions[1].amount
    assert_equal -11111, transactions[1].amount_in_pennies
    assert_equal '22222A', transactions[1].fit_id
    assert_equal '0000009611', transactions[1].check_number
    assert_equal nil, transactions[1].sic
    assert_equal nil, transactions[1].sic_desc
    assert_equal 'CHECK', transactions[1].payee
    assert_equal 'Download from usbank.com.', transactions[1].memo

    assert_equal :DIRECTDEP, transactions[2].type
    assert_equal OfxParser::Transaction::TYPE[:DIRECTDEP], transactions[2].type_desc
    assert_equal DateTime.civil(2007,6,14,12,0,0), transactions[2].date
    assert_equal '1111.11', transactions[2].amount
    assert_equal 111111, transactions[2].amount_in_pennies
    assert_equal 'X34AE33', transactions[2].fit_id
    assert_equal nil, transactions[2].check_number
    assert_equal nil, transactions[2].sic
    assert_equal nil, transactions[2].sic_desc
    assert_equal 'ELECTRONIC DEPOSIT BAR INC', transactions[2].payee
    assert_equal 'Download from usbank.com. BAR INC', transactions[2].memo

    assert_equal :CREDIT, transactions[3].type
    assert_equal OfxParser::Transaction::TYPE[:CREDIT], transactions[3].type_desc
    assert_equal DateTime.civil(2007,6,19,12,0,0), transactions[3].date
    assert_equal '11.11', transactions[3].amount
    assert_equal 1111, transactions[3].amount_in_pennies
    assert_equal '8 8 9089743', transactions[3].fit_id
    assert_equal nil, transactions[3].check_number
    assert_equal nil, transactions[3].sic
    assert_equal nil, transactions[3].sic_desc
    assert_equal 'ATM DEPOSIT US BANK ANYTOWNAS', transactions[3].payee
    assert_equal 'Download from usbank.com. US BANK ANYTOWN ASUS1', transactions[3].memo

    # Test Bank Account #2 ---------------------------------------------------

    acct = accts[1]

    assert_equal '103333333333', acct.number
    assert_equal '033000033', acct.routing_number
    assert_equal :CHECKING, acct.type
    assert_equal '1234.09', acct.balance
    assert_equal 123409, acct.balance_in_pennies
    assert_equal DateTime.civil(2007,6,23,14,26,35,Rational(-5, 24)), acct.balance_date
    assert_equal '9C24229A0077EAA50000011353C9E00743FD', acct.transaction_uid

    statement = acct.statement

    assert_equal 'USD', statement.currency
    assert_equal DateTime.civil(2007,6,4,19,0,0,Rational(-5, 24)), statement.start_date
    assert_equal DateTime.civil(2007,6,22,19,0,0,Rational(-5, 24)), statement.end_date

    transactions = statement.transactions
    assert_equal 1, transactions.size

    assert_equal :CREDIT, transactions[0].type
    assert_equal OfxParser::Transaction::TYPE[:CREDIT], transactions[0].type_desc
    assert_equal DateTime.civil(2007,6,19,12,0,0), transactions[0].date
    assert_equal '11.11', transactions[0].amount
    assert_equal 1111, transactions[0].amount_in_pennies
    assert_equal '8 8 9089743', transactions[0].fit_id
    assert_equal nil, transactions[0].check_number
    assert_equal nil, transactions[0].sic
    assert_equal nil, transactions[0].sic_desc
    assert_equal 'ATM DEPOSIT US BANK ANYTOWNAS', transactions[0].payee
    assert_equal 'Download from usbank.com. US BANK ANYTOWN ASUS1', transactions[0].memo

  end

  def test_creditcard
    ofx = OfxParser::OfxParser.parse(OFX_FILES[:creditcard])

    acct = ofx.credit_accounts.first

    assert_equal 'XXXXXXXXXXXX1111', acct.number
    assert_equal '19000.99', acct.remaining_credit
    assert_equal 1900099, acct.remaining_credit_in_pennies
    assert_equal DateTime.civil(2007,6,23,19,20,13), acct.remaining_credit_date
    assert_equal '-1111.01', acct.balance
    assert_equal -111101, acct.balance_in_pennies
    assert_equal DateTime.civil(2007,6,23,19,20,13), acct.balance_date
    assert_equal '0', acct.transaction_uid

    statement = acct.statement

    assert_equal 'USD', statement.currency
    assert_equal DateTime.civil(2007,5,9,12,0,0), statement.start_date
    assert_equal DateTime.civil(2007,6,8,12,0,0), statement.end_date

    transactions = statement.transactions
    assert_equal 3, transactions.size

    assert_equal :DEBIT, transactions[0].type
    assert_equal OfxParser::Transaction::TYPE[:DEBIT], transactions[0].type_desc
    assert_equal DateTime.civil(2007,5,10,17,0,0), transactions[0].date
    assert_equal '-19.17', transactions[0].amount
    assert_equal -1917, transactions[0].amount_in_pennies
    assert_equal 'xx', transactions[0].fit_id
    assert_equal nil, transactions[0].check_number
    assert_equal '5912', transactions[0].sic
    assert_equal OfxParser::Mcc::CODES['5912'], transactions[0].sic_desc
    assert_equal 'WALGREEN      34638675 ANYTOWN', transactions[0].payee
    assert_equal '', transactions[0].memo

    assert_equal :DEBIT, transactions[1].type
    assert_equal OfxParser::Transaction::TYPE[:DEBIT], transactions[1].type_desc
    assert_equal DateTime.civil(2007,5,12,17,0,0), transactions[1].date
    assert_equal '-12.0', transactions[1].amount
    assert_equal -1200, transactions[1].amount_in_pennies
    assert_equal 'yy-56', transactions[1].fit_id
    assert_equal nil, transactions[1].check_number
    assert_equal '7933', transactions[1].sic
    assert_equal OfxParser::Mcc::CODES['7933'], transactions[1].sic_desc
    assert_equal 'SUNSET BOWL            ANYTOWN', transactions[1].payee
    assert_equal '', transactions[1].memo

    assert_equal :CREDIT, transactions[2].type
    assert_equal OfxParser::Transaction::TYPE[:CREDIT], transactions[2].type_desc
    assert_equal DateTime.civil(2007,5,26,17,0,0), transactions[2].date
    assert_equal '11.01', transactions[2].amount
    assert_equal 1101, transactions[2].amount_in_pennies
    assert_equal '78-9', transactions[2].fit_id
    assert_equal nil, transactions[2].check_number
    assert_equal '0000', transactions[2].sic
    assert_equal nil, transactions[2].sic_desc
    assert_equal 'ELECTRONIC PAYMENT-THANK YOU', transactions[2].payee
    assert_equal '', transactions[2].memo

    assert_equal 1, ofx.accounts.size
    assert_equal [], ofx.signup_account_info
  end

  def test_multiple_credit_cards
    ofx = OfxParser::OfxParser.parse(OFX_FILES[:creditcards])

    accts = ofx.credit_accounts
    assert_equal 2, ofx.accounts.length
    assert_equal [], ofx.signup_account_info

    accts.each_with_index do |acct, idx|
      assert_equal "XXXXXXXXXXXX#{(idx + 1).to_s * 4}", acct.number
      assert_equal '19000.99', acct.remaining_credit
      assert_equal 1900099, acct.remaining_credit_in_pennies
      assert_equal DateTime.civil(2007,6,23,19,20,13), acct.remaining_credit_date
      assert_equal '-1111.01', acct.balance
      assert_equal -111101, acct.balance_in_pennies
      assert_equal DateTime.civil(2007,6,23,19,20,13), acct.balance_date
      assert_equal '0', acct.transaction_uid

      statement = acct.statement

      assert_equal 'USD', statement.currency
      assert_equal DateTime.civil(2007,5,9,12,0,0), statement.start_date
      assert_equal DateTime.civil(2007,6,8,12,0,0), statement.end_date

      transactions = statement.transactions
      assert_equal 3, transactions.size

      assert_equal :DEBIT, transactions[0].type
      assert_equal OfxParser::Transaction::TYPE[:DEBIT], transactions[0].type_desc
      assert_equal DateTime.civil(2007,5,10,17,0,0), transactions[0].date
      assert_equal '-19.17', transactions[0].amount
      assert_equal -1917, transactions[0].amount_in_pennies
      assert_equal 'xx', transactions[0].fit_id
      assert_equal nil, transactions[0].check_number
      assert_equal '5912', transactions[0].sic
      assert_equal OfxParser::Mcc::CODES['5912'], transactions[0].sic_desc
      assert_equal 'WALGREEN      34638675 ANYTOWN', transactions[0].payee
      assert_equal '', transactions[0].memo

      assert_equal :DEBIT, transactions[1].type
      assert_equal OfxParser::Transaction::TYPE[:DEBIT], transactions[1].type_desc
      assert_equal DateTime.civil(2007,5,12,17,0,0), transactions[1].date
      assert_equal '-12.0', transactions[1].amount
      assert_equal -1200, transactions[1].amount_in_pennies
      assert_equal 'yy-56', transactions[1].fit_id
      assert_equal nil, transactions[1].check_number
      assert_equal '7933', transactions[1].sic
      assert_equal OfxParser::Mcc::CODES['7933'], transactions[1].sic_desc
      assert_equal 'SUNSET BOWL            ANYTOWN', transactions[1].payee
      assert_equal '', transactions[1].memo

      assert_equal :CREDIT, transactions[2].type
      assert_equal OfxParser::Transaction::TYPE[:CREDIT], transactions[2].type_desc
      assert_equal DateTime.civil(2007,5,26,17,0,0), transactions[2].date
      assert_equal '11.01', transactions[2].amount
      assert_equal 1101, transactions[2].amount_in_pennies
      assert_equal '78-9', transactions[2].fit_id
      assert_equal nil, transactions[2].check_number
      assert_equal '0000', transactions[2].sic
      assert_equal nil, transactions[2].sic_desc
      assert_equal 'ELECTRONIC PAYMENT-THANK YOU', transactions[2].payee
      assert_equal '', transactions[2].memo
    end
  end

  def test_account_listing
    ofx = OfxParser::OfxParser.parse(OFX_FILES[:list])

    cc_info = ofx.signup_account_info.first
    assert_equal 'CREDIT CARD ************1111', cc_info.desc
    assert_equal 'XXXXXXXXXXXX1111', cc_info.number

    assert_equal 0, ofx.accounts.size
  end

  def test_monetary_support_call
    t = OfxParser::Transaction.new
    t.amount = '-11.1'

    assert_nothing_raised { t.amount_in_pennies }
    assert_raise(NoMethodError) { t.amount_in_whatever }

    assert t.respond_to?(:amount_in_pennies)
    assert !t.respond_to?(:amount_in_whatever)
  end

  def test_malformed_header_parses
    assert_nothing_raised do
      OfxParser::OfxParser.parse(OFX_FILES[:malformed_header])
    end
  end

  class X
    include OfxParser::MonetarySupport
    extend OfxParser::MonetaryClassSupport
    attr_accessor :amount
    monetary_vars :amount
  end

  def test_original_method
    x = X.new
    assert_equal :a_b, x.original_method('a_b_in_pennies')
    assert_equal :a, x.original_method('a_in_pennies')
  end

  def test_for_pennies
    amounts = {
      '-11.1' => -111,
      '-11.110' => -1111,
      '-11.11101' => -1111,
      '11.11' => 1111,
      '11,11' => 1111,
      '1' => 100,
      '1.0' => 100,
      '-1.0' => -100,
      '' => nil
    }

    x =  X.new

    amounts.each do |actual, expected|
      x.amount = actual
      assert_equal expected, x.amount_in_pennies, "#{actual.inspect} should give #{expected.inspect}"
    end
  end

end
