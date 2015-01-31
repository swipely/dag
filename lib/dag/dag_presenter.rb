require 'graphviz'
class DagPresenter

  def add_vertex(v)
    fail NotImplementedError, "#{self.class} must implement add_vertex"
  end

  def add_edge(presented_from,presented_to, e)
    fail NotImplementedError, "#{self.class} must implement add_edge"
  end

  def present(opts={})
    fail NotImplementedError, "#{self.class} must implement present"
  end

end