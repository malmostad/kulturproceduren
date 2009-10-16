require 'soap/rpc/driver'

module KP::Elit

class ElitKpPortType < ::SOAP::RPC::Driver
  DefaultEndpointUrl = "http://10.121.150.171:9080/elit-kpService/elit-kpPort"

  Methods = [
    [ nil,
      "getDistricts",
      [ ["in", "input", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "dummy"]],
        ["out", "districts", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "districtList"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ nil,
      "getSchools",
      [ ["in", "input", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "districtId"]],
        ["out", "schools", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "schoolList"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ nil,
      "getGroups",
      [ ["in", "input", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "schoolId"]],
        ["out", "groups", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "groupList"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ nil,
      "getAgeGroups",
      [ ["in", "input", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "groupId"]],
        ["out", "ageGroups", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "ageGroupList"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ nil,
      "getSchoolContacts",
      [ ["in", "input", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "contactsSchoolId"]],
        ["out", "schoolContacts", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "contactList"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ nil,
      "getGroupContacts",
      [ ["in", "input", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "contactsGroupId"]],
        ["out", "groupContacts", ["::SOAP::SOAPElement", "http://www.malmo.se/esb/schema/elit-kp", "contactList"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ]
  ]

  def initialize(endpoint_url = nil)
    endpoint_url ||= DefaultEndpointUrl
    super(endpoint_url, nil)
    self.mapping_registry = ElitKpMappingRegistry::EncodedRegistry
    self.literal_mapping_registry = ElitKpMappingRegistry::LiteralRegistry
    init_methods
  end

private

  def init_methods
    Methods.each do |definitions|
      opt = definitions.last
      if opt[:request_style] == :document
        add_document_operation(*definitions)
      else
        add_rpc_operation(*definitions)
        qname = definitions[0]
        name = definitions[2]
        if qname.name != name and qname.name.capitalize == name.capitalize
          ::SOAP::Mapping.define_singleton_method(self, qname.name) do |*arg|
            __send__(name, *arg)
          end
        end
      end
    end
  end
end


end
