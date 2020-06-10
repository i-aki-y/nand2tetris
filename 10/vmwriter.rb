class VMWriter

  def initialize
    @cmds = []
    @sub_cmds = []
    @is_subroutine = false

    @buf = []
    @is_buf = false
  end

  def start_subroutine
    @is_subroutine = true
  end

  def end_subroutine
    @is_subroutine = false
  end

  def start_buf
    @is_buf = true
  end

  def end_buf
    @is_buf = false
  end

  def concat_buf
    @buf.each {|cmd| push_cmd(cmd) }
    @buf = []
  end

  def push_cmd(cmd)
    if @is_buf
      @buf.push(cmd)
    else

      if @is_subroutine
        @sub_cmds.push(cmd)
      else
        @cmds.push(cmd)
      end

    end

    cmd
  end

  def dump_vm
    @cmds.join("\n")
  end

  def concat_sub_cmds
    @cmds += @sub_cmds
    @sub_cmds = []
  end

  def write_push(seg, index)
    push_cmd("push #{seg} #{index}")
  end

  def write_pop(seg, index)
    push_cmd("pop #{seg} #{index}")
  end

  def write_arithmetic(cmd)
    push_cmd("#{cmd}")
  end

  def write_label(label)
    push_cmd("label #{label}")
  end

  def write_goto(label)
    push_cmd("goto #{label}")
  end

  def write_if(label)
    push_cmd("if-goto #{label}")
  end

  def write_call(name, nargs)
    push_cmd("call #{name} #{nargs}")
  end

  def write_function(name, nlocal)
    push_cmd("function #{name} #{nlocal}")
  end

  def write_return
    push_cmd("return")
  end

  def close

  end

end
