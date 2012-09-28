module OfxParser
  module MonetaryClassSupport

    attr_accessor :monies

    def monetary_vars(*methods) #:nodoc:
      self.monies ||= []
      self.monies += methods
    end
  end

  module MonetarySupport
    # Returns pennies for a given string amount, i.e:
    #  '-123.45' => -12345
    #  '123' => 12300
    def pennies_for(amount)
      return nil if amount == ""
      int, fraction = amount.scan(/\d+/)
      i = (fraction.to_s.strip =~ /[1-9]/) ? "#{int}#{fraction[0,2]}".to_i : int.to_i * 100
      amount =~ /^\s*-\s*\d+/ ? -i : i
    end

    def original_method(meth) #:nodoc:
      meth.to_s.sub('_in_pennies','').to_sym rescue nil
    end

    def monetary_method_call?(meth) #:nodoc:
      orig = original_method(meth)
      self.class.monies.include?(orig) && meth.to_s == "#{orig}_in_pennies"
    end

    def method_missing(meth, *args) #:nodoc:
      if (monetary_method_call?(meth))
        pennies_for(send(original_method(meth)))
      else
        super
      end
    end

    def respond_to?(meth) #:nodoc:
      monetary_method_call?(meth) ? true : super
    end

  end

  # This class is returned when a parse is successful.
  # == General Notes
  # * currency symbols are an iso4217 3-letter code
  # * language is defined by iso639 3-letter code
  class Ofx
    attr_accessor :header, :sign_on, :signup_account_info,
                  :bank_accounts, :credit_accounts,
                  :investment_accounts

    def accounts
      [ bank_accounts, credit_accounts, investment_accounts ].flatten!.compact!
    end

    def bank_account #:nodoc:
      warn "DEPRECATION WARNING: bank_account() is deprecated and may be removed from future releases, use bank_accounts() instead."
      bank_accounts.first
    end

    def credit_card #:nodoc:
      warn "DEPRECATION WARNING: credit_card() is deprecated and may be removed from future releases, use credit_accounts() instead."
      credit_accounts.first
    end
  end

  class SignOn
    attr_accessor :status, :date, :language, :institute
  end

  class AccountInfo
    attr_accessor :desc, :number, :bank_id, :type
  end

  class Account
    attr_accessor :number, :statement, :transaction_uid, :routing_number, :account_key
  end

  class BankAccount < Account
    TYPE = [:CHECKING, :SAVINGS, :MONEYMRKT, :CREDITLINE]
    attr_accessor :type, :balance, :balance_date, :branch_id

    include MonetarySupport
    extend MonetaryClassSupport
    monetary_vars :balance

    undef type
    def type
      @type.to_s.upcase.to_sym
    end
  end

  class CreditAccount < Account
    attr_accessor :remaining_credit, :remaining_credit_date, :balance, :balance_date

    include MonetarySupport
    extend MonetaryClassSupport
    monetary_vars :remaining_credit, :balance
  end

  class InvestmentAccount < Account
    attr_accessor :broker_id, :positions, :margin_balance, :short_balance, :cash_balance

    include MonetarySupport
    extend MonetaryClassSupport
    monetary_vars :margin_balance, :short_balance, :cash_balance
  end

  class Statement
    attr_accessor :currency, :transactions, :start_date, :end_date
  end

  class Transaction
    attr_accessor :type, :date, :amount, :fit_id, :check_number, :sic, :memo, :payee, :payee_id

    include MonetarySupport
    extend MonetaryClassSupport
    monetary_vars :amount

    TYPE = {
      :CREDIT      => "Generic credit",
      :DEBIT       => "Generic debit",
      :INT         => "Interest earned or paid ",
      :DIV         => "Dividend",
      :FEE         => "FI fee",
      :SRVCHG      => "Service charge",
      :DEP         => "Deposit",
      :ATM         => "ATM debit or credit",
      :POS         => "Point of sale debit or credit ",
      :XFER        => "Transfer",
      :CHECK       => "Check",
      :PAYMENT     => "Electronic payment",
      :CASH        => "Cash withdrawal",
      :DIRECTDEP   => "Direct deposit",
      :DIRECTDEBIT => "Merchant initiated debit",
      :REPEATPMT   => "Repeating payment/standing order",
      :OTHER       => "Other"
    }

    def type_desc
      TYPE[type]
    end

    undef type
    def type
      @type.to_s.strip.upcase.to_sym
    end

    undef sic
    def sic
      @sic == "" ? nil : @sic
    end

    def sic_desc
      Mcc::CODES[sic]
    end
  end

  class Position
  end

  # Status of a sign on
  class Status
    attr_accessor :code, :severity, :message

    CODES = {
      '0'	    => 'Success',
      '2000'	=> 'General error',
      '15000'	=> 'Must change USERPASS',
      '15500'	=> 'Signon invalid',
      '15501'	=> 'Customer account already in use',
      '15502'	=> 'USERPASS Lockout'
    }

    def code_desc
      CODES[code]
    end

    undef code
    def code
      @code.to_s.strip
    end

  end

  class Institute
    attr_accessor :name, :id
  end

end
