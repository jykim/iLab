
#Retrieved Document Set
#
class ResultDocumentSet < DocumentSet
  include ILabHelper, Math
  attr_accessor :rl , :precs , :avg_precs , :recalls , :rank_limit, :weight
  def initialize( name , o = {})
    weight = 1.0
    super(name , o)
    @min_scores = [] ; @max_scores = []
  end
  
  def clear
    super.clear
    #info "[ResultDocumentSet::clear]"
    @prec = {}
    @precs = {}
    @avg_precs = {}
  end
  
  def min_score(qid)
    @min_scores[qid] ||= @dhq[qid].map{|d| d.score}.min
  end
  
  def max_score(qid)
    @max_scores[qid] ||= @dhq[qid].map{|d| d.score}.max
  end  
  
  def compare_to(rds)
    @docs.sort_by{|d|d.rank}.map{|d|d.did} == rds.docs.sort_by{|d|d.rank}.map{|d|d.did}
  end
  
  def export
    fwrite "#{@name}.qry" , "Generated by iLab"
    fwrite "#{@name}.res" , @docs.map{|d| [d.qid , 'Q0' , d.did , d.rank , d.score , d.remark].join(' ')}.join("\n")
  end
  
  def self.create_by_filter(set_name , old_set , &filter)
    rs = DocumentSet.create_by_filter(set_name , old_set , &filter)
    rs.dhq.each{|k,v| v.sort_by{|d|d.score}.reverse.each_with_index{|d,i| d.rank = i+1}}
    rs.export ; rs
  end
  
  # Create new document set by fusion of given sets
  # - Overlapping subcollections
  def self.create_by_fusion(set_name , old_sets , o = {} , &filter)
    ds_new = ResultDocumentSet.new(set_name)
    docs = {} ; doc_counts = {}
    limit_docs = o[:limit_docs] || 1000
    
    old_sets.each do |ds|
      ds.docs.find_all{|e| (block_given?)? filter.call(e,ds) : true }.each do |d|
        docs[d.qid] , doc_counts[d.qid] = {} , {} if !docs[d.qid]
        #Document is never seen
        if !docs[d.qid][d.did]
          docs[d.qid][d.did] , doc_counts[d.qid][d.did] = d.dup , 1
          docs[d.qid][d.did].score = d.score_r(ds.max_score) 
        else
          case o[:mode]
          when 'CombSUM'
            docs[d.qid][d.did].score += d.score_r(ds.max_score)
          when 'CombMNZ'
            docs[d.qid][d.did].score += d.score_r(ds.max_score) ; doc_counts[d.qid][d.did] += 1
          else
            err "Duplicated document was found!"
          end
        end
      end#doc
    end#docset
    
    #Multiply by Count
    case o[:mode]
    when 'CombMNZ'
      docs.each{|k,v| v.each{|k2,v2| v2.score *= doc_counts[k][k2] }}
    end

    #Calculate Rank & Export
    docs.each{|k,v| v.values.sort_by{|d|d.score}.reverse.each_with_index{|d,i| d.rank = i+1}}
    ds_new.import_docs( docs.map{|k,v|v.values.sort_by{|d|d.rank}[0..(limit_docs-1)]}.flatten )
    ds_new.export ; ds_new
  end
  
  # Create new document set by merging given sets
  # - Non-overlapping sets
  # - Collection statistics
  def self.create_by_merge(set_name , old_sets , o = {} , &filter)
    rs_new = ResultDocumentSet.new(set_name)
    docs = {}
    limit_docs = o[:limit_docs] || 1000
    col_weight = o[:col_weight] || 0.4
    col_score = {}

    # Calculate collection scores
    old_sets[0].qrys.each_with_index do |q,i|
      #debugger
      #begin
      col_score[q.qid] = $engine.get_cs_score(q.text, o[:cs_type], o)
      #rescue StandardError
        
      #`end
      #col_score[q.qid] = qs.get_col_score(q.text , o)
      #$i.fwrite("cscore_#{qs.name}_#{o[:cs_type]}.out", "#{qs.name} #{q.qid} #{col_score[q.qid]}", :mode=>((i == 0)? 'w' : 'a'))
      #info "[create_by_merge] col_score for #{qs.name} #{q.qid} #{col_score[q.qid]}"
    end
    # Score for each subcollection
    old_sets.each do |qs|
      info "[create_by_merge] col_type = #{qs[:col_type]} query set size = #{qs.qrys.size}"
      qs.rs.docs.find_all{|e| (block_given?)? filter.call(e,qs.rs) : true }.each do |d|
        docs[d.qid] = {} if !docs[d.qid]
        docs[d.qid][d.did] = d.dup
        score_raw = case (o[:norm] || :minmax)
        when :none
          d.score
        when :max
          d.score_r(qs.rs.max_score(d.qid))
        when :minmax
          d.score_rn(qs.rs.max_score(d.qid),qs.rs.min_score(d.qid))
        end
        #debugger if qs.rs.max_score > 0
        $avg_doc_score = {} if !$avg_doc_score
        $avg_doc_score[d.qid] = {} if !$avg_doc_score[d.qid]
        $avg_doc_score[d.qid][qs[:template]] = {} if !$avg_doc_score[d.qid][qs[:template]]
        $avg_doc_score[d.qid][qs[:template]][qs[:col_type]] = (Math.exp(qs.rs.max_score(d.qid)) + Math.exp(qs.rs.min_score(d.qid)))/2
        info "[create_by_merge] #{qs.rs.name} max_score: #{qs.rs.max_score(d.qid)} min_score: #{qs.rs.min_score(d.qid)}" if d.qid == 1 && d.rank == 1
        if d.qid.to_i <= 0
          err "[create_by_merge] invalid qid = #{d.qid} for did = #{d.did}"
          next
        end
        #debugger
        #err "[create_by_merge] col_score[#{d.qid}][#{qs[:col_type]}] = nil" if !col_score[d.qid][qs[:col_type]]
        case (o[:merge_type] || :cori)
        when :cori
          score_doc = Math.exp(score_raw)
          #debugger
          score_col = score_doc * col_score[d.qid][qs[:col_type]]
          docs[d.qid][d.did].score = (score_col * col_weight + score_doc) / (1 + col_weight)
          info "[create_by_merge] #{docs[d.qid][d.did].score.r3} = #{score_col.r3} * #{col_weight} + #{score_doc.r3} (#{d.did})" if d.qid == 1 && d.rank <= 3
        when :multiply
          score_doc = Math.exp(score_raw)
          score_col = col_score[d.qid][qs[:col_type]]
          docs[d.qid][d.did].score = (score_col * score_doc)
          info "[create_by_merge] #{docs[d.qid][d.did].score.r3} = #{score_col.r3} * #{score_doc.r3} (#{d.did})" if d.qid == 1 && d.rank <= 3
          #debugger
        else
          err "[create_by_merge] invalid merge type"
        end
      end#doc
    end#docset

    #Calculate Rank & Export
    docs.each{|k,v| v.values.sort_by{|d|d.score}.reverse.each_with_index{|d,i| d.rank = i+1}}
    rs_new.import_docs( docs.sort_by{|k,v|k.to_i}.map{|e|e[1].values.sort_by{|d|d.rank}[0..(limit_docs-1)]}.flatten )
    rs_new.export ; rs_new
  end
  
  #Precision@rank
  def prec_at(rank)
    if @prec[rank] then return @prec[rank] end
    @precs[rank] = {} if !@precs[rank]
    @docs.group_by{|d|d.qid}.each do |qid,ds|
      doc_count = ds.find_all{|d|d.rank <= rank}.size.to_f
      #raise DataError, "[prec_at] Insufficient Docs qid : #{qid} docs : #{doc_count} < #{rank}" if doc_count < rank
      warn("[prec_at] Insufficient Docs qid : #{qid} docs : #{doc_count} < #{rank}") if doc_count < rank
      @precs[rank][qid] = ds.find_all{|d|d.relevance > 0 && d.rank <= rank}.size / doc_count if doc_count >= rank
    end
    @prec[rank] = @precs[rank].values.mean
  end

  #Average Precision
  # - macro / micro
  def avg_prec(macro = true)
    precs = []
    @docs.group_by{|d|d.qid}.each do |qid,ds|
      if macro
        precs << ds.map{|d| (d.relevance > 0)?true:false}.avg_prec
      else# micro
        ds.each_with_index do |d , i|
          if d.relevance == true
            no_rels += 1
            precs << no_rels / (i+1).to_f
          end
        end
      end
    end
    puts "[avg_prec] #@name : #{precs.size} queries / #{docs.size} docs"
    @avg_prec = precs.mean      
  end
  
  def avg_recall
    @recalls = {}
    @docs.group_by{|d|d.qid}.each do |qid,docs|
      @recalls[qid] = @docs.find_all{|d| d.relevance > 0}.size / @rl.docs.find_all{|d|d.qid == qid && d.relevance > 0}.size.to_f
      #puts "map of #{qid} : "
    end
    @avg_recall = @recalls.values.mean
  end
end
