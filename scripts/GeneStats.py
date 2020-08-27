#!/usr/bin/env python
from Bio import SeqIO

import sys

# genome_file = "demo.fasta"
# annotation_file = "demo.gff"
USAGE="\n\
                Usage: ./Genestats.py genome.fa Gene.gff3 \n\
                genome.fa:      Genome in fasta format\n\
                Gene.gff3: Gff of annotations\n "

try:
    genome_file = sys.argv[1]
    annotation_file = sys.argv[2]
except IndexError:
        print (USAGE)
        exit()




class GenomeFeature(object):
    def __init__(self):
        self.scaffold = None
        self.start = None
        self.end = None
        self.strand = None
        self.attribute =None

    def __len__(self):
        return self.end-self.start+1

    def load_gff_record(self,gff_record):
        self.scaffold = gff_record.scaffold
        self.start = gff_record.start
        self.end = gff_record.end
        self.strand = gff_record.strand
        self.attribute = gff_record.attribute


class Gff_Record():
    def __init__(self,record_string):
        record = record_string.strip().split("\t")
        self.scaffold = record[0]
        self.source = record[1]
        self.feature = record[2]
        self.start = int(record[3])
        self.end = int(record[4])
        self.score = record[5]
        self.strand = record[6]
        self.frame = record[7]
        self.attribute = record[8]


class Transcript(GenomeFeature):
    def __init__(self,genome):
        super(Transcript,self).__init__()
        self.genome=genome
        self.exons=[]
        self.introns = []

    def add_exon(self,exon):
        self.exons.append(exon)

    def retrive_introns(self):
        if len(self.exons) == 0:
            print("fail to find an exon in this Transcript: %s"%(self.attribute))
            self.add_intron(self.start, self.end)
        elif len(self.exons) > 1:
            self.exons.sort(key=lambda x:x.start)
            for i in range(1,len(self.exons)):
                if self.exons[i-1].end +1 < self.exons[i].start -1:
                    self.add_intron(self.exons[i-1].end + 1, self.exons[i].start - 1)

    def add_intron(self,start,end):
        new_intron = GeneFeature(self, "intron")
        new_intron.scaffold = self.scaffold
        new_intron.start = start
        new_intron.end = end
        new_intron.strand = self.strand
        new_intron.attribute = "intron at %s[%d:%d] %s" % (new_intron.scaffold, new_intron.start, new_intron.end, new_intron.strand)
        self.introns.append(new_intron)


class Gene(GenomeFeature):
    def __init__(self,genome):
        super(Gene,self).__init__()
        self.genome=genome
        self.exons=[]
        self.introns = []
        self.transcripts = []

    def add_exons(self):
        for transcript in self.transcripts:
            self.exons += transcript.exons

    def add_introns(self):
        for transcript in self.transcripts:
            self.introns += transcript.introns


class GeneFeature(GenomeFeature):

    def __init__(self,gene,feature_type):
        super(GeneFeature,self).__init__()
        self.gene=gene
        self.feature_type=feature_type

    def get_sequence(self):

        # would get 1 more base at 3' end
        genome=self.gene.genome
        scaffold = genome.genomeid_dict[self.scaffold]

        if self.strand == "+":
            return scaffold[self.start-1:self.end+1]
        elif self.strand == "-":
            return scaffold[self.start-2:self.end].reverse_complement()


class Node():
    def __init__(self,number,ntype):
        self.number=number
        self.type=ntype

    def return_number(self):
        return self.number


class IntergenicRegions():
    def __init__(self,genome,scaffold):
        self.genome=genome
        self.scaffold = scaffold
        self.nodes=[Node(1,"scaffold_start"),Node(len(genome.genomeid_dict[scaffold]),"scaffold_end")]

    def update(self,gene_inteval):
        gene_start=Node(gene_inteval[0],"gene_start")
        gene_end=Node(gene_inteval[1],"gene_end")
        self.nodes.insert(0,gene_start)
        self.nodes.append(gene_end)
        self.nodes.sort(key=Node.return_number)
        idx_gene_start=self.nodes.index(gene_start)
        idx_gene_end=self.nodes.index(gene_end)

        if idx_gene_start%2 == 0:
            nodes_lst1 = self.nodes[0:idx_gene_start] or []
        else:
            new_node=Node(gene_inteval[0]-1,"inter_end")
            nodes_lst1 = self.nodes[0:idx_gene_start]+ [new_node]

        if idx_gene_end%2 == 1:
                try:
                        nodes_lst2 = self.nodes[idx_gene_end+1:]
                except IndexError:
                        nodes_lst2 = []

        else:
            new_node=Node(gene_inteval[1]+1,"inter_start")
            nodes_lst2 = [new_node] + self.nodes[idx_gene_end+1:]

        self.nodes=nodes_lst1+nodes_lst2

    def call_length_inter(self):
        inter_len_lst = []
        for i in range(0,len(self.nodes)//2):
            if self.nodes[2*i+1].type=="scaffold_end" or self.nodes[2*i].type=="scaffold_start":
                continue
            elif self.nodes[2*i+1].type!="inter_end" or self.nodes[2*i].type!="inter_start":
                print ("got errors in call intergenetic lenth")
            length = self.nodes[2*i+1].number - self.nodes[2*i].number + 1
            inter_len_lst.append(length)
        return inter_len_lst


class Genome():
    def __init__(self,file):
        self.genomeid_dict = SeqIO.to_dict(SeqIO.parse(file,"fasta"))
        self.genes=[]
        self.transcripts=[]
        self.intergenicregions_all={}
        self.cnt_donors={}
        self.cnt_acceptors={}
        self.genes_with_intron=[]
        for scaffold in self.genomeid_dict:
            self.intergenicregions_all[scaffold]=IntergenicRegions(self,scaffold)

    def annotate_genes(self,anno):
        with open("introns.fa","w"):
            pass
        with open(anno) as annotation:
            for line in annotation:
                if not line.strip():
                    continue
                elif line.strip()[0] == "#":
                    continue
                record = Gff_Record(str(line))
                if record.feature == "gene":
                    new_gene = Gene(self)
                    new_gene.load_gff_record(record)
                    self.genes.append(new_gene)
                elif record.feature in ["transcript","mRNA"]:
                    new_transcript=Transcript(self)
                    new_transcript.load_gff_record(record)
                    self.transcripts.append(new_transcript)
                    if new_transcript.start<new_gene.start or new_transcript.end>new_gene.end:
                        print ("unrecognised transcript\n")
                    new_gene.transcripts.append(new_transcript)
                elif record.feature == "exon":
                    new_exon=GeneFeature(new_transcript,"exon")
                    new_exon.load_gff_record(record)
                    if new_exon.start<new_transcript.start or new_exon.end>new_transcript.end:
                        print ("unrecognised exon\n")
                    else:
                        new_transcript.add_exon(new_exon)

        for transcript in self.transcripts:
            transcript.retrive_introns()

            for intron in transcript.introns:
                sequence = intron.get_sequence()
                with open("introns.fa", "a") as intr:
                    intr.write(">"+intron.attribute + "\n")
                    intr.write(str(sequence.seq[:-1])+"\n")
                donor = sequence[:2]
                self.cnt_donors[str(donor.seq).upper()] = self.cnt_donors.get(str(donor.seq).upper(), 0) + 1
                acceptor = sequence[-3:]
                self.cnt_acceptors[str(acceptor.seq).upper()] = self.cnt_acceptors.get(str(acceptor.seq).upper(), 0) + 1
           
        for gene in self.genes:
            gene.add_exons()
            gene.add_introns()
            gene_inteval = (gene.start, gene.end)
            self.intergenicregions_all[gene.scaffold].update(gene_inteval)

    def get_number_of_genes(self):
        return len(self.genes)

    def get_average_gene_length(self):
   #     with open("gene_lenth.lst", "w"):
    #        pass
        length_distri = list(map(len,self.genes))
     #   with open("gene_lenth.lst","a") as genlen:
      #          genlen.write("\n".join([str(x) for x in length_distri])+"\n")
        total_length = sum(length_distri)
        
        cds_length = sum(map(lambda x: sum(map(len,x.exons)), self.genes))
        number_of_genes=self.get_number_of_genes()
        return total_length/(number_of_genes*1.0),cds_length/(number_of_genes*1.0)

    def get_number_of_scaffolds(self):
        return len(self.genomeid_dict)

    def get_length_and_number_of_exons(self):
        total = 0
        number = 0
        for gene in self.genes:
            len_exons=sum(map(len,gene.exons))
            total += len_exons
            number += len(gene.exons)
        return total,number

    def get_number_of_genes_with_introns(self):
        number = 0
        for gene in self.genes:
            if len(gene.introns) > 0 :
                number += 1
                self.genes_with_intron.append(gene)
        return number

    def get_length_and_number_of_introns(self):
        total = 0
        number = 0
     #  empty the file if exist
        with open("introns_lenth.lst", "w"):
            pass
        for gene in self.genes_with_intron:
            len_introns_distribution = list(map(len,gene.introns))
            with open("introns_lenth.lst","a") as inlen:
                inlen.write("\n".join([str(x) for x in len_introns_distribution])+"\n")

            len_introns=sum(len_introns_distribution)
            total += len_introns
            number += len(gene.introns)
        return total,number

    def get_inter_length_and_number(self):
        total = 0
        number = 0
        for inter_per_scaffold in self.intergenicregions_all.values():
            length_lst = inter_per_scaffold.call_length_inter()
            total += sum(length_lst)
            number += len(length_lst)
        return total,number

    def print_stats(self):
        number_genes= self.get_number_of_genes()
        average_gene_length,average_cds_length = self.get_average_gene_length()
        number_of_scaffolds = self.get_number_of_scaffolds()
        length_exons,number_exons = self.get_length_and_number_of_exons()
        number_genes_with_introns = self.get_number_of_genes_with_introns()
        length_introns,number_introns = self.get_length_and_number_of_introns()
        length_inters,number_inters = self.get_inter_length_and_number()
        donors_stats="/".join(map(lambda x:"%s:%f"%(x,self.cnt_donors[x]/(number_introns*1.0)*100),self.cnt_donors))
        acceptors_stats="/".join(map(lambda x:"%s:%f"%(x[:2]+"|"+x[2:],self.cnt_acceptors[x]/(number_introns*1.0)*100),self.cnt_acceptors))

        print ("Number of genes: \t %d"%(number_genes))
        print ("Average gene length: \t %f"%(average_gene_length))
        print ("Average cds length: \t %f"%(average_cds_length))
        print ("Number of sequences in genome: \t %d"%(number_of_scaffolds))

        print ("Total number of exons: \t %d"%(number_exons))
        print ("Average number of exons per gene: \t %f"%(number_exons/(number_genes*1.0)))
        print ("Average exon length: \t %f"%(length_exons/(number_exons*1.0)))

        print ("Number of genes with introns: %d"%(number_genes_with_introns))
        print ("Total number of introns: \t %d"%(number_introns))
        print ("Total intron length: \t %d"%(length_introns))
        print ("Average intron length: \t %f"%(length_introns/(number_introns*1.0)))
        print ("Average number of introns per gene: \t %f"%(number_introns/(number_genes*1.0)))

        print ("Splice donors (%%): \t %s"%(donors_stats))
        print ("Splice acceptors (%%): \t %s"%(acceptors_stats))

        print ("Number of intergenic regions: \t %d"%(number_inters))
        print ("Total intergenic region length:  \t %d"%(length_inters))
        print ("Average intergenic region length: \t %f"%(length_inters/(number_inters*1.0)))


genome1 = Genome(genome_file)
genome1.annotate_genes(annotation_file)
genome1.print_stats()





