require_relative 'dag/vertex'
require_relative 'dag/dag_presenter'

class DAG

  Edge = Struct.new(:origin, :destination, :properties)

  attr_reader :vertices, :edges

  #
  # Create a new Directed Acyclic Graph
  #
  # @param [Hash] options configuration options
  # @option options [Module] mix this module into any created +Vertex+
  #
  def initialize(options = {})
    @vertices = []
    @edges = []
    @mixin = options[:mixin]
  end

  def add_vertex(payload = {})
    Vertex.new(self, payload).tap {|v|
      v.extend(@mixin) if @mixin
      @vertices << v
    }
  end

  def add_edge(attrs)
    origin = attrs[:origin] || attrs[:source] || attrs[:from] || attrs[:start]
    destination = attrs[:destination] || attrs[:sink] || attrs[:to] || attrs[:end]
    properties = attrs[:properties] || {}
    raise ArgumentError.new('Origin must be a vertex in this DAG') unless
      is_my_vertex?(origin)
    raise ArgumentError.new('Destination must be a vertex in this DAG') unless
      is_my_vertex?(destination)
    raise ArgumentError.new('A DAG must not have cycles') if origin == destination
    raise ArgumentError.new('A DAG must not have cycles') if destination.has_path_to?(origin)
    Edge.new(origin, destination, properties).tap {|e| @edges << e }
  end

  def subgraph(predecessors_of = [], successors_of = [])


    (predecessors_of + successors_of).each { |v|
      raise ArgumentError.new('You must supply a vertex in this DAG') unless
        is_my_vertex?(v)
      }

    result = DAG.new({mixin: @mixin})
    vertex_mapping = {}

    # Get the set of predecessors verticies and add a copy to the result
    predecessors_set = Set.new(predecessors_of)
    predecessors_of.each { |v| v.ancestors(predecessors_set) }

    predecessors_set.each do |v|
      vertex_mapping[v] = result.add_vertex(payload=v.payload)
    end

    # Get the set of successor vertices and add a copy to the result
    successors_set = Set.new(successors_of)
    successors_of.each { |v| v.descendants(successors_set) }

    successors_set.each do |v|
      vertex_mapping[v] = result.add_vertex(payload=v.payload) unless vertex_mapping.include? v
    end

    # get the unique edges
    edge_set = (
      predecessors_set.flat_map(&:incoming_edges) +
      successors_set.flat_map(&:outgoing_edges)
    ).uniq

    # Add them to the result via the vertex mapping
    edge_set.each do |e|
      result.add_edge(
        from: vertex_mapping[e.origin],
        to: vertex_mapping[e.destination],
        properties: e.properties)
    end

    return result
  end

  def render(presenter, args=[])
    # Given a presenter class which implements DagPresenter transform the modeled information
    raise ArgumentError,
      "Unknown presenter class: #{presenter} - must inherit from DagPresenter" unless
        presenter < DagPresenter

    presentation = presenter.new(*args)

    vertex_mapping = {}
    # Holds context for processing edges

    vertices.each do |v|
      vertex_mapping[v] = presentation.add_vertex(v)
    end

    edges.each do |e|
      presentation.add_edge(
          vertex_mapping[e.origin],
          vertex_mapping[e.destination],
          e
        )
    end

    return presentation
  end

  private

  def is_my_vertex?(v)
    #puts "Kind of: #{v.class}"
    #puts "Verts dag is self #{v.dag == self}"
    v.kind_of?(Vertex) and v.dag == self
  end


end

