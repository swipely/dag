require 'graphviz'
class GraphVizPresenter
  attr_reader :graph
  class << self; attr_accessor :vertex_presenter_blk, :edge_presenter_blk end

  self.vertex_presenter_blk = proc do |v|
    {
      shape: 'record',
      #label: "{Vertex}",
      color: 'black',
      fillcolor: 'white',
      style: 'filled',
    }
  end

  self.edge_presenter_blk = proc do |e|
    {
      dir: 'forward',
      color: 'blue'
    }
  end

  def initialize
    @graph = GraphViz.new(:G, :type => :digraph)
    @vcounter=-1
  end

  def add_vertex(v)
    @vcounter +=1
    graph.add_node(@vcounter.to_s, self.class.vertex_presenter_blk.call(v))
  end

  def add_edge(from,to,e)
    graph.add_edge(from,to,self.class.edge_presenter_blk.call(e))
  end

  def output(opts={})
    @graph.output(**opts)
  end


end