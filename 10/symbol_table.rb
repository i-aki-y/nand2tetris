class SymbolItem
  attr_accessor :name, :type, :kind, :index

  def initialize(name, type, kind, index)
    @name = name
    @type = type
    @kind = kind
    @index = index
  end
end

class SymbolTable

  def initialize
    # define class, subroutine scopes
    @symbol_tables = [{}, {}]
  end

  def class_table
    @symbol_tables[0]
  end

  def subroutine_table
    @symbol_tables[1]
  end

  def start_subroutine
    @symbol_tables[1] = {}
  end

  def define(name, type, kind)

    table = get_table(kind)

    if table.has_key?(name)
      raise "#{name} has been already defined in the class scope"
    end

    next_index = var_count(kind)
    table[name] = SymbolItem.new(name, type, kind, next_index)
  end

  def get_table(kind)
    case kind
    when :static, :field
      return class_table
    when :arg, :var
      return subroutine_table
    end
  end

  def var_count(kind)
    table = get_table(kind)
    items = table.values.select{|item| item.kind == kind}
    items.size
  end

  def something_of(name, something)

    if subroutine_table.has_key?(name)
      return subroutine_table[name].send(something)
    else
      return class_table[name].send(something)
    end

  end

  def kind_of(name)
    something_of(name, "kind")
  end

  def type_of(name)
    something_of(name, "type")
  end

  def index_of(name)
    something_of(name, "index")
  end

  def get_item(name)
    if subroutine_table.has_key?(name)
      subroutine_table[name]
    else
      class_table[name]
    end
  end

  def debug_dump
    p subroutine_table
    p class_table

  end
end
