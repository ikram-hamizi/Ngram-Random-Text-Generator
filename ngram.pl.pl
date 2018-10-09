# !/usr/bin/perl

#********************************************************************************************************************************************************
#	
#								***************** Programming Assignment 2 (n-gram) - VCU [19/02/2018] *****************
# Author    : Ikram Hamizi
# Class     : Intro. to NLP
# Professor : Bridget McInnes
# 
#********************************************************************************************************************************************************
#   DESCRIPTION: A program that generates a given number of sentences based on the N-gram model.
#   ------------
# - Input : Int(n, m), "String.txt" @(input files) { n= ngram model, m= num(sentences) }
# - Output: m(sentences)
#
#********************************************************************************************************************************************************
#   SPECIFICATIONS:
#	---------------
# 1. All text is converted to lower case.
# 2. Punctuation is included and separated from words as tokens in the n-gram models.
# 3. Numeric data treated as tokens.
# 4. Sentence boundaries: <end> = [".", "?", "!"]
# 5. If the len(sentence) in input text file < n --> discard (not used when computing n-gram probabilities).
# 6- #In this program, the sentences between '[]{}()' are discarded since they are usually an explanation and not a continuation of the previous sentence.
# 7- "Boundaries" specifications can be changed (Read Note). (Consider new line as an <e> tag, or ignore it).
#
#********************************************************************************************************************************************************

						#################/!\ /!\ /!\ /!\ /!\ IMPORTANT NOTE /!\ /!\ /!\ /!\ /!\##################
						#########################################################################################
						#For the Assignment specifications on "boundaries", go to the fileTokenizer() subroutine.
						#########################################################################################

#********************************************************************************************************************************************************

use strict;
use Data::Dumper qw(Dumper);
use List::MoreUtils qw(first_index indexes);

#1- MY VARS
#############

my $specialChars = '[^A-Za-z0-9\.!?;,()"\s+\[\]{}\'\—-]'; #Anything that is not in this set, we keep it (terminating chars are treated separately).
my $annoyingChars = '[^A-Za-z0-9\.!?,;\-\'<>]'; #Anything that is not these is discarded ('<>' are kept to match <e> and <s>)
my $leftBraces = '[\[{("]';
my $rightBraces ='["\]})]';
my $terminatingChars = '.?!';
my $end = '<e>'; #end tag
my $n = 3;

my %hash1; #n-gram  table
my %hash2; #n-1gram table

my @array = ();


#2- FUNCTIONS
#############

#1~ Generates n-gram and n-1gram tables - input = word/token (will be added to array(history) and the hash1 table)
sub ngramTableGenerator()
{
	my ($word) = $_[0];
	if(scalar @array < $n - 1) #2 
	{	
		# print "\n---------SOLOADD : $word\n"; #DEBUG
		push (@array, $word);
		return;
	}
	if(scalar @array == $n - 1)
	{
		my $history = join " ", @array;
		# print "\n---------HISTORY: $history---------\n"; #DEBUG
		# print "---------WORD   : $word------------\n\n"; #DEBUG

		$hash1{$history}{$word}++;
		$hash2{$history}++;

		push (@array, $word); #Adds word to the rear of the array
		shift @array; #Remove first word from history in array
	}
}

#2~ Generates n-1 (<start>)
sub startTagToTable()
{
	for(my $i=0; $i<$n-1; $i++)
	{
		&ngramTableGenerator("<s>");
	}
}

#3~ Reads files and tokenizes(splits) on regex: /\s+/

# 	- This function ignores ($annoyingChars) and treats ($terminatingChars) and ($specialChars) as separate tokens.
#	- If no ($terminatingChars) was present then <e> is added as a (terminatingChar) -> [Specification #7]
#	- After each ($terminatingChar) or <e>, n-1 <s> tags are added.

sub fileTokenizer() #input: String "name_of_file".txt #NO SPACES ALLOWED
{	
	my ($fileName) = $_[0];

	print "I am file: [ $fileName ]\n";
	@array = (); #Empty Array of History

	my @line;
	my $token; #Tokens from @line
	my $q; #Variable = $token (duplicate)

	&startTagToTable(); #Add n-1 <s> tags indicating the start of the first sentence in a file.

	open(HANDLER, "<", $fileName) or die "Shoot! Could Not Open file: $fileName\n";
	while(<HANDLER>)
	{
		chomp;
		# print; #DEBUG
		# print "\n";

		#Split each file on white spaces
		@line = split(/\s+/, $_);
		my $countBraces = 0;

		if(scalar @line > $n) 
		{
			#**************************************THIS SECTION CAN BE OMITTED************************************
			#*****************************************************************************************************

			#******If the last token of the array is not a ($terminatingChar), then it is a new line --> add end tag: <e>
			#******If this section is left uncommented, the following is treated as 2 separate sentences:
			##** "He went down the stairs
			##** She also went down the stairs."

			# print " I am end of line: ++ $line[scalar @line - 1] ++\n"; # $terminatingChars #DEBUG
			
			# unless($line[scalar @line - 1]=~m/[$terminatingChars]/i) 
			# {
			# 	push @line, $end;   #add <e>
			# }

			#*****************************************************************************************************
			#*****************************************************************************************************

			for(my $j=0; $j< scalar @line; $j++) #[K-pop, (abbreviation]
			{	
				$token = $line[$j];
				$q = lc($token);
				if ($q =~m/($leftBraces)/i)
				{
					# print "[j = $j] i am left brace $1, and i'll be ignored--\n\n"; #DEBUG

					#Continue searching for a matching right brace, and ignore the whole sentence
					my @matchingBraceIndex = indexes { /$rightBraces/ } @line;
					if($countBraces>=scalar @matchingBraceIndex)
					{
						last;
					}
					$j = $matchingBraceIndex[$countBraces];
					# print "MY MATCH IS: $j --\n\n"; #DEBUG
					$countBraces++;
					# print "->[j = $j] my matching pair is before $line[$j]\n\n\n"; #DEBUG
				}
				elsif($q =~m/($end|[$terminatingChars])/i)
				{
					# print "I am a terminating char: $1 ==$token==\n";
					if($q =~m/(\w+)($end|[$terminatingChars])/i)
					{
						&ngramTableGenerator(lc($1));
						&ngramTableGenerator($2);
					}
					elsif($q =~m/^($end|[$terminatingChars])/i)
					{
						&ngramTableGenerator($1);
					}
					&startTagToTable(); #adds n-1 <s> to hash tables
				}
				elsif($q =~m/(.+)($specialChars)/i) #e.g.: Yes/ or Definition:
				{
					# print "I am special >> $2\n";
					&ngramTableGenerator(lc($1));
					&ngramTableGenerator($2);
				}
				elsif($q =~m/(\w*)($annoyingChars)(\w*)/i)
				{
					# print "I am annoying >> '$2'\n";
					#Do not take annoying chars such as '[' and ')' as tokens
					if(length $1 > 0)
					{
						# print "I am 1: [ $1 ]\n";
						&ngramTableGenerator(lc($1));
					}
					if(length $3 > 0)
					{
						# print "I am 3: [ $3 ])\n";
						&ngramTableGenerator(lc($3));
					}
				}
				else
				{
					&ngramTableGenerator($q);
				}
			}
		}
	}
	#Remove one set of <s> tags that were added at the end of the file.
	close(HANDLER);
}

#4~ Given a History of n-1grams, it caalculates probability of the words that come after it and chooses 1 of them. input: String(History)
sub inputHistoryOutputWord()
{
	my ($HISTORY) = $_[0];
	my $rand;
	my %ArrProb;
	
	foreach my $word(keys %{$hash1{$HISTORY}})
	{
		if($hash2{$HISTORY} ne 0)
		{
			$ArrProb{$word} = $hash1{$HISTORY}{$word} / $hash2{$HISTORY};
		}
	} 
	$rand = rand();
	my $prev_prob = 0;
	my $prob;

	foreach $prob(sort values %ArrProb)
	{
		$prev_prob = $prev_prob + $prob;
		$prob = $prev_prob;
		if($rand <= $prob)
		{
			my @winners = grep {$ArrProb{$_} eq $prob} keys %ArrProb;
			return $winners[0];
		}
	}
	return "";
}

#5~ Generate Sentence.
sub sentenceGenerator()
{
	my @ngram;
	#Add n-1 <s> tags indicating the beginning of a sentence.
	for(my $i=0; $i<$n-1; $i++)
	{	
		push @ngram, '<s>';
	}	
	my $HISTORY;
	my $SENTENCE;
	my $DETECT_STOP;

	while(1)
	{
		$HISTORY = join " ", @ngram;
		$DETECT_STOP = &inputHistoryOutputWord($HISTORY);
		# print "SENTENCE: ".$SENTENCE."\n"; #DEBUG

		if($DETECT_STOP =~m/[$terminatingChars]/i || $DETECT_STOP eq "<e>")
		{
			last; #Break out from loop if terminatingChar is detected.
		}
		push (@ngram, $DETECT_STOP);
		shift @ngram;
		$SENTENCE = $SENTENCE.$DETECT_STOP." ";
	}
	print "- [START]: ".&capitalizeFirstLetter($SENTENCE);
	print ".\n";
}

#6~ Capitalize first letter of the sentence
sub capitalizeFirstLetter() #input: String (Sentence)
{
	my ($str) = $_[0];
	my $first = (uc substr $str, 0, 1);
	my $next = substr $str, 1;
	return $first."".$next;
}

print "\n\nThis program generates random sentences based on an n-gram model.\n
Author: Ikram Hamizi - [19/02/2018 - VCU]\n*****************************************************************\n\n";
#*Reading Arguments from CMD

$n = $ARGV[0]; #n
my $m = $ARGV[1]; #m
shift;

while(shift) #Names of files
{
	if(scalar @ARGV == 0)
	{	
		last;
	}
	&fileTokenizer($ARGV[0]);
}

# DEBUG_START*************************

# print "------------------------\n";
# print Dumper \%hash1;
# print "------------------------\n";
# print Dumper \%hash2;
# print "------------------------\n";

# DEBUG_END***************************

print "> I will generate $m sentences: \n\n";

#**************GENERATING STARTS HERE******************
for(my $i=0; $i<$m; $i++)
{
	print "\n";
	print ($i+1);
	&sentenceGenerator();
}
#******************END OF PROGRAM**********************