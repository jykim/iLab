
require "rexml/document"
include REXML
def dbir_check(qid, did, rel)
  doc = REXML::Document.new File.new( to_path("doc_"+did+".xml") )
  s = ""
  return "" if rel != "-1"
  case qid
  when "1"
    if doc.match_cs("locations" , "SC") && rel == "1" : s += "+1" 
    elsif !doc.match_cs("locations" , "SC") && rel == "2" : s += "-1" 
    end
  when "2"
    if (doc.match("locations" , "rhode") || doc.match("locations" , "providence")) && rel != "2" : s += "+1" 
    elsif (!doc.match("locations" , "rhode") && !doc.match("locations" , "providence")) && rel == "2" : s += "-1"
    end
  when "3"
    if (doc.match_cs("locations" , "TX") || doc.match("locations" , "Lubbock")) && rel == "1" : s += "+1" 
    elsif (!doc.match_cs("locations" , "TX") && !doc.match("locations" , "Lubbock")) && rel == "2" : s += "-1"
    end
  when "4"
    if (doc.match_cs("locations" , "TX") || doc.match("locations" , "Dallas")) && rel == "1" : s += "+1" 
    elsif (!doc.match_cs("locations" , "TX") && !doc.match("locations" , "Dallas")) && rel == "2" : s += "-1"
    end
  when "5"
    if (doc.match_cs("locations" , "TN") || doc.match("locations" , "Memphis")) && rel != "2" : s += "+1" 
    elsif (!doc.match_cs("locations" , "TN") && !doc.match("locations" , "Memphis")) && rel == "2" : s += "-1"
    end
  when "6"
    if (doc.match_cs("locations" , "KS") || doc.match("locations" , "Riley")) && rel != "2" : s += "+1" 
    elsif (!doc.match_cs("locations" , "KS") && !doc.match("locations" , "Riley")) && rel == "2" : s += "-1"
    end
  when "7"
    if (doc.match_cs("locations" , "CA") || doc.match("locations" , "Angeles")) && rel != "2" : s += "+1" 
    elsif (!doc.match_cs("locations" , "CA") && !doc.match("locations" , "Angeles")) && rel == "2" : s += "-1"
    end
  when "8"
    if (doc.match("locations" , "Trenton") || doc.match("locations" , "Chester")) && rel != "2" : s += "+1" 
    elsif (!doc.match("locations" , "Trenton") && !doc.match("locations" , "Chester")) && rel == "2" : s += "-1"
    end
  when "9"
    if (doc.match_cs("locations" , "CA") || doc.match("locations" , "Torrance")) && rel != "2" : s += "+1" 
    elsif (!doc.match_cs("locations" , "CA") && !doc.match("locations" , "Torrance")) && rel == "2" : s += "-1"
    end
  when "10"
    if (doc.match_cs("locations" , "KS") || doc.match("locations" , "Kansas")) && rel != "2" : s += "+1" 
    elsif (!doc.match_cs("locations" , "KS") && !doc.match("locations" , "Kansas")) && rel == "2" : s += "-1"
    end
  when "21"
    s += "+1" if (doc.match("DesiredJobTitle" , "Property Manager"))
    s += "-1" if (!doc.match_cs("locations" , "CT") && !doc.match("locations" , "hartford"))      
  when "22"
    s += "+1" if doc.match("DesiredJobTitle" , "Writer")
    s += "+1" if (doc.match("Skills" , "Java") || doc.match("skills" , "Coldfusion")) 
    s += "-1" if (!doc.match_cs("locations" , "AZ") && !doc.match("locations" , "Scottsdale"))
  when "23"
    s += "+1" if(doc.match("DesiredJobTitle" , "Receptionist") && doc.match("skills" , "Office")) 
    s += "-1" if (!doc.match_cs("locations" , "AZ") )
  when "25"
    s += "+1" if (doc.match("DesiredJobTitle" , "RN") || doc.match("DesiredJobTitle" , "Nurse"))
    s += "+1" if doc.match("experience" , "ER")
    s += "-1" if (!doc.match_cs("locations" , "AZ") && !doc.match("locations" , "Mesa"))
  when "26"
    s += "+1" if( doc.match("DesiredJobTitle" , "Truck"))
    s += "+1" if doc.match("experience" , "Sanitation")
    s += "-1" if (!doc.match_cs("locations" , "AZ") && !doc.match("locations" , "Mesa"))
  when "27"
    s += "+1" if( doc.match("DesiredJobTitle" , "Swim") && doc.match("DesiredJobTitle" , "Instructor"))
    s += "-1" if (!doc.match("locations" , "Houston") && !doc.match("locations" , "Stafford") && !doc.match("locations" , "Sugar Land"))
  when "28"
    s += "+1" if( doc.match("DesiredJobTitle" , "Law Enforcement") || doc.match("DesiredJobTitle" , "Police") || doc.match("DesiredJobTitle" , "Security Officer"))
    s += "-1" if (!doc.match("locations" , "Montana") && !doc.match("locations" , "Kalispell"))
  when "29"
    s += "+1" if( doc.match("DesiredJobTitle" , "Turbine") || doc.match("DesiredJobTitle" , "Combustor"))
    s += "-1" if (!doc.match("locations" , "IN") && !doc.match("locations" , "Indianapolis"))
  when "30"
    s += "+1" if( doc.match("DesiredJobTitle" , "Wastewater"))
    s += "-1" if (!doc.match("locations" , "IL") && !doc.match("locations" , "Chicago"))
  end
  s
end

module REXML
  class Document
    def match(element, keyword)
      match_cs(element, keyword) || match_cs(element, keyword.upcase) || match_cs(element, keyword.downcase)
    end

    def match_cs(element, keyword)
      XPath.match(self, "//#{element}[contains(.,'#{keyword}')]").size > 0
    end
  end
end