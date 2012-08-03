class VernacularLabel < SemanticVernacularDataSource

	attr_accessor :uri,
								:label,
								:creator,
								:created_date_time

	def initialize(uri)
		@uri = uri
		vl = self.class.query(init_query)[0]
		@label = vl["label"]["value"]
		@creator = SVUser.new(vl["user"]["value"])
		@created_date_time = vl["dateTime"]["value"]
	end

	def self.insert(svd, label, user)
		update(insert_rdf(svd, label, user))
	end

	private

	def init_query
		QUERY_PREFIX +
		%(SELECT DISTINCT ?label ?user ?dateTime
			WHERE {
				<#{@uri}> a/rdfs:subClassOf* svf:VernacularLabel .
				<#{@uri}> rdfs:label ?label .
				<#{@uri}> svf:proposedBy ?user .
				<#{@uri}> svf:proposedAt ?dateTime .
			})
	end

	def self.insert_rdf(svd, label, user)
		QUERY_PREFIX +
		%(INSERT DATA {
				<#{svd["uri"]}> 
					rdfs:subClassOf
						#{insert_has_object_value_restriction_rdf(
							SVF_NAMESPACE + "hasLabel", label["uri"])} . 
				<#{label["uri"]}>
					a owl:NamedIndividual, svf:VernacularLabel;
					rdfs:label "#{label["value"]}"^^rdfs:Literal;
					svf:hasID "#{label["id"]}"^^xsd:positiveInteger;
					svf:proposedAt "#{Time.now.strftime("%FT%T%:z")}"^^xsd:dateTime;
					svf:proposedBy <#{user["uri"]}> . 
			})
	end

	def self.delete_rdf(uri)
		QUERY_PREFIX +
		%(DELETE WHERE {
				?svd rdfs:subClassOf ?c .
				?c owl:hasValue <#{uri}> .
				?c ?p1 ?o1 .
				<#{uri}> ?p2 ?o2 . 
			})
	end

	def self.accept_rdf(uri)
		QUERY_PREFIX +
		%()
	end

end