require 'spec_helper'

describe DAG do

  context 'when new' do
    its(:vertices) { should be_empty }
    its(:edges) { should be_empty }
  end

  context 'with one vertex' do
    it 'has only that vertex' do
      v = subject.add_vertex
      subject.vertices.should == [v]
    end

    it 'has no edges' do
      v = subject.add_vertex
      v.outgoing_edges.should be_empty
      v.incoming_edges.should be_empty
    end
  end

  context 'using a mix-in module' do
    subject { DAG.new(mixin: Thing) }
    let(:v) { subject.add_vertex(name: 'Fred') }

    module Thing
      def my_name
        payload[:name]
      end
    end

    it 'mixes the module into evey vertex' do
      (Thing === v).should be_true
    end

    it 'allows the module to access the payload' do
      v.my_name.should == 'Fred'
    end
  end

  context 'creating an edge' do
    let(:v1) { subject.add_vertex }

    context 'when valid' do
      let(:v2) { subject.add_vertex }
      let!(:e1) { subject.add_edge(origin: v1, destination: v2) }

      it 'leaves the origin vertex' do
        v1.outgoing_edges.should == [e1]
      end

      it 'arrives at the destination vertex' do
        v2.incoming_edges.should == [e1]
      end

      it 'adds no other edges' do
        v1.incoming_edges.should be_empty
        v2.outgoing_edges.should be_empty
      end

      it 'allows multiple edges between a pair of vertices' do
        expect { subject.add_edge(origin: v1, destination: v2) }.to_not raise_error
      end
    end

    context 'when invalid' do
      it 'requires an origin vertex' do
        expect { subject.add_edge(to: v1) }.to raise_error(ArgumentError)
      end

      it 'requires a destination vertex' do
        expect { subject.add_edge(from: v1) }.to raise_error(ArgumentError)
      end

      it 'requires the endpoints to be vertices' do
        expect { subject.add_edge(from: v1, to: 23) }.to raise_error(ArgumentError)
        expect { subject.add_edge(from: 45, to: v1) }.to raise_error(ArgumentError)
      end

      it 'requires the endpoints to be in the same DAG' do
        v2 = DAG.new.add_vertex
        expect { subject.add_edge(from: v1, to: v2) }.to raise_error(ArgumentError)
        expect { subject.add_edge(from: v2, to: v1) }.to raise_error(ArgumentError)
      end

      it 'rejects an edge that would create a loop' do
        v2 = subject.add_vertex
        v3 = subject.add_vertex
        v4 = subject.add_vertex
        subject.add_edge from: v1, to: v2
        subject.add_edge from: v2, to: v3
        subject.add_edge from: v3, to: v4
        expect { subject.add_edge from: v4, to: v1 }.to raise_error(ArgumentError)
      end

      it 'rejects an edge from a vertex to itself' do
        expect { subject.add_edge from: v1, to: v1 }.to raise_error(ArgumentError)
      end
    end

    context 'with different keywords' do
      let(:v1) { subject.add_vertex }
      let(:v2) { subject.add_vertex }
      let!(:e1) { subject.add_edge(origin: v1, destination: v2) }

      it 'allows :source and :sink' do
        subject.add_edge(source: v1, sink: v2).should == e1
      end

      it 'allows :from and :to' do
        subject.add_edge(from: v1, to: v2).should == e1
      end

      it 'allows :start and :end' do
        subject.add_edge(start: v1, end: v2).should == e1
      end

    end

  end

end

