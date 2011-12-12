require 'rubygems'
require 'hpricot'
require 'time'
require 'date'

%w(ofx mcc).each do |fn|
  require File.dirname(__FILE__) + "/#{fn}"
end

module OfxParser
  VERSION = '1.0.2'

  class OfxParser

    # Creates and returns an Ofx instance when given a well-formed OFX document,
    # complete with the mandatory key:pair header.
    def self.parse(ofx)
      ofx = ofx.respond_to?(:read) ? ofx.read.to_s : ofx.to_s

      return Ofx.new if ofx == ""

      header, body = pre_process(ofx)

      ofx_out = parse_body(body)
      ofx_out.header = header
      ofx_out
    end

    # Designed to make the main OFX body parsable. This means adding closing tags
    # to the SGML to make it parsable by hpricot.
    #
    # Returns an array of 2 elements:
    # * header as a hash,
    # * body as an evily pre-processed string ready for parsing by hpricot.
    def self.pre_process(ofx)
      header, body = ofx.split(/\n{2,}|:?<OFX>/, 2)

      header = Hash[*header.gsub(/^\r?\n+/,'').split(/\r\n/).collect do |e| 
        e.split(/:/,2)
      end.flatten]

      body.gsub!(/>\s+</m, '><')
      body.gsub!(/\s+</m, '<')
      body.gsub!(/>\s+/m, '>')
      body.gsub!(/<(\w+?)>([^<]+)/m, '<\1>\2</\1>')

      [header, body]
    end

    # Takes an OFX datetime string of the format:
    # * YYYYMMDDHHMMSS.XXX[gmt offset:tz name]
    # * YYYYMMDD
    # * YYYYMMDDHHMMSS
    # * YYYYMMDDHHMMSS.XXX
    #
    # Returns a DateTime object. Milliseconds (XXX) are ignored.
    def self.parse_datetime(date)
      if /\A\s*
          (\d{4})(\d{2})(\d{2})           ?# YYYYMMDD            1,2,3
          (?:(\d{2})(\d{2})(\d{2}))?      ?# HHMMSS  - optional  4,5,6
          (?:\.(\d{3}))?                  ?# .XXX    - optional  7
          (?:\[([-+]?[\.\d]+)\:\w{3}\])?  ?# [-n:TZ] - optional  8,9
          \s*\z/ix =~ date
        year = $1.to_i
        mon = $2.to_i
        day = $3.to_i
        hour = $4.to_i
        min = $5.to_i
        sec = $6.to_i
        # DateTime does not support usecs.
        # usec = 0
        # usec = $7.to_f * 1000000 if $7
        off = Rational($8.to_i, 24) # offset as a fraction of day. :|
        DateTime.civil(year, mon, day, hour, min, sec, off)
      end
    end

  private
    def self.parse_body(body)
      doc = Hpricot.XML(body)

      ofx = Ofx.new

      ofx.sign_on = build_signon((doc/"SIGNONMSGSRSV1/SONRS"))
      ofx.signup_account_info = build_info((doc/"SIGNUPMSGSRSV1/ACCTINFOTRNRS"))
      ofx.bank_account = build_bank((doc/"BANKMSGSRSV1/STMTTRNRS")) unless (doc/"BANKMSGSRSV1").empty?
      ofx.credit_card = build_credit((doc/"CREDITCARDMSGSRSV1/CCSTMTTRNRS")) unless (doc/"CREDITCARDMSGSRSV1").empty?
      #build_investment((doc/"SIGNONMSGSRQV1"))

      ofx
    end

    def self.build_signon(doc)
      sign_on = SignOn.new
      sign_on.status = build_status((doc/"STATUS"))
      sign_on.date = parse_datetime((doc/"DTSERVER").inner_text)
      sign_on.language = (doc/"LANGUAGE").inner_text

      sign_on.institute = Institute.new
      sign_on.institute.name = ((doc/"FI")/"ORG").inner_text
      sign_on.institute.id = ((doc/"FI")/"FID").inner_text
      sign_on
    end

    def self.build_info(doc)
      account_infos = []

      (doc/"ACCTINFO").each do |info_doc|
        acc_info = AccountInfo.new
        acc_info.desc = (info_doc/"DESC").inner_text
        acc_info.number = (info_doc/"ACCTID").inner_text
        account_infos << acc_info
      end

      account_infos
    end

    def self.build_bank(doc)
      acct = BankAccount.new

      acct.transaction_uid = (doc/"TRNUID").inner_text.strip
      acct.number = (doc/"STMTRS/BANKACCTFROM/ACCTID").inner_text
      acct.routing_number = (doc/"STMTRS/BANKACCTFROM/BANKID").inner_text
      acct.type = (doc/"STMTRS/BANKACCTFROM/ACCTTYPE").inner_text.strip
      acct.balance = (doc/"STMTRS/LEDGERBAL/BALAMT").inner_text
      acct.balance_date = parse_datetime((doc/"STMTRS/LEDGERBAL/DTASOF").inner_text)

      statement = Statement.new
      statement.currency = (doc/"STMTRS/CURDEF").inner_text
      statement.start_date = parse_datetime((doc/"STMTRS/BANKTRANLIST/DTSTART").inner_text)
      statement.end_date = parse_datetime((doc/"STMTRS/BANKTRANLIST/DTEND").inner_text)
      acct.statement = statement

      statement.transactions = (doc/"STMTRS/BANKTRANLIST/STMTTRN").collect do |t|
        build_transaction(t)
      end

      acct
    end

    def self.build_credit(doc)
      acct = CreditAccount.new

      acct.number = (doc/"CCSTMTRS/CCACCTFROM/ACCTID").inner_text
      acct.transaction_uid = (doc/"TRNUID").inner_text.strip
      acct.balance = (doc/"CCSTMTRS/LEDGERBAL/BALAMT").inner_text
      acct.balance_date = parse_datetime((doc/"CCSTMTRS/LEDGERBAL/DTASOF").inner_text)
      acct.remaining_credit = (doc/"CCSTMTRS/AVAILBAL/BALAMT").inner_text
      acct.remaining_credit_date = parse_datetime((doc/"CCSTMTRS/AVAILBAL/DTASOF").inner_text)

      statement = Statement.new
      statement.currency = (doc/"CCSTMTRS/CURDEF").inner_text
      statement.start_date = parse_datetime((doc/"CCSTMTRS/BANKTRANLIST/DTSTART").inner_text)
      statement.end_date = parse_datetime((doc/"CCSTMTRS/BANKTRANLIST/DTEND").inner_text)
      acct.statement = statement

      statement.transactions = (doc/"CCSTMTRS/BANKTRANLIST/STMTTRN").collect do |t|
        build_transaction(t)
      end

      acct
    end

    # for credit and bank transactions.
    def self.build_transaction(t)
      transaction = Transaction.new
      transaction.type = (t/"TRNTYPE").inner_text
      transaction.date = parse_datetime((t/"DTPOSTED").inner_text)
      transaction.amount = (t/"TRNAMT").inner_text
      transaction.fit_id = (t/"FITID").inner_text
      transaction.payee = (t/"PAYEE").inner_text + (t/"NAME").inner_text
      transaction.memo = (t/"MEMO").inner_text
      transaction.sic = (t/"SIC").inner_text
      transaction.check_number = (t/"CHECKNUM").inner_text if transaction.type == :CHECK
      transaction
    end


    def self.build_investment(doc)

    end

    def self.build_status(doc)
      status = Status.new
      status.code = (doc/"CODE").inner_text
      status.severity = (doc/"SEVERITY").inner_text
      status.message = (doc/"MESSAGE").inner_text
      status
    end

  end
end
