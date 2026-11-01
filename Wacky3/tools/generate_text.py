"""English localization source; re-run after editing TEXT."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
TEXT = {
'CIV':'The Ministry of Almost', 'SHORT':'Ministry of Almost', 'ADJECTIVE':'Ministerial',
'LEADER':'Acting Chancellor Penultimate', 'TRAIT':'Always the Challenger',
'TRAIT_HELP':'At the beginning of each owner-turn, compare researched technologies with the leading living rival major team. At 0-2 technologies behind: no bonus. At 3-5: +1 [ICON_RESEARCH] Science and +1 [ICON_CULTURE] Culture in every city. At 6 or more: +2 Science and +1 Culture in every city. Bonuses are capped, do not stack, and disappear as you catch up. Your own team, city-states, barbarians and eliminated civilizations are excluded.',
'CIV_PEDIA':'Second Place Is Just First Place in Disguise.[NEWLINE][NEWLINE]The Ministry of Almost is a fictional bureaucratic republic with a treasury full of silver medals. Narrow defeats became lessons, delayed discoveries inspired better schools, and emergency educational improvements helped the country recover whenever another nation pulled far ahead. Its institutions reward recovery rather than permanent disadvantage. When the Ministry catches up, its emergency programs close.',
'STRATEGY':'Build a normal Science or Culture economy. Temporary catch-up yields support recovery; they cannot replace growth, Libraries, Universities, specialists and defensive preparation. Never delay important research to enlarge the gap.',
'LEADER_PEDIA':'Acting Chancellor Penultimate has served for forty-seven years without winning an election. Every election she loses by exactly one vote; every victor resigns before taking office. A middle-aged woman in an elaborate silver ceremonial uniform, she presides beneath the portrait of the first Chancellor, surrounded by hundreds of silver medals. Repeated disappointment has made her a patient, exceptionally competent administrator.',
'UNIT':'Second Wind Guard',
'UNIT_HELP':'Replaces the Spearman, retaining its active Community Patch properties and normal upgrades, with exactly +1 Movement. Second Wind veterans gain +15% defensive strength while occupying territory owned by their own team. This bonus never increases attack strength and is removed outside team-owned territory. The veteran identity survives normal upgrades; the extra Movement does not.',
'UNIT_PEDIA':"We're Not Finished Yet![NEWLINE][NEWLINE]These mobile defensive troops protect schools and government offices while the Ministry rebuilds. Each regiment carries a silver medal from a campaign it almost won. Their discipline survives promotion to more modern service.",
'UNIT_STRATEGY':'Use the additional Movement to reinforce threatened friendly cities. Fight defensively on your own territory. Normal Spearman strengths and weaknesses still apply.',
'ACADEMY':'Runner-Up Academy',
'ACADEMY_HELP':'Replaces the Library and retains every normal effect of the active Community Patch Library. Adds +1 [ICON_CULTURE] Culture permanently. Adds exactly +1 [ICON_PRODUCTION] Production while the current owner-turn snapshot is six or more technologies behind, provided the Ministry owns this city. The temporary Production disappears if the Academy is lost.',
'ACADEMY_PEDIA':'Excellence Is a Work in Progress.[NEWLINE][NEWLINE]Every lecture begins with a failed experiment and ends with an improved proposal. Silver medals decorate the reading rooms. The Academy supplies ordinary Library education alongside a lasting cultural tradition and temporary industrial training during serious technological disadvantage.',
'ACADEMY_STRATEGY':'Build early for normal Library Science and permanent Culture. At a gap of six, the Academy also supplies one temporary Production. Plan an economy that can succeed after this bonus ends.',
'IDENTITY':'Second Wind Veteran', 'IDENTITY_HELP':'Retains the Second Wind Guard defensive benefit through normal upgrades. +15% defense while standing in team-owned territory; no attack bonus.',
'DEFENSE':'Second Wind: Home Defense', 'DEFENSE_HELP':'+15% defensive strength on team-owned territory. No attack strength modifier. Removed on leaving qualifying territory.',
'DUMMY':'Ministry Emergency Program', 'DUMMY_HELP':'Internal recurring yield controller. Unbuildable; managed by the current owner-turn snapshot.',
'GREETING_1':"Welcome! You're actually our second diplomatic visitor today. The first one cancelled, so technically you're first! Congratulations!",
'WAR_1':'We have tolerated second place for centuries. Unfortunately for you, we have decided to pursue a different ranking.',
'DEFEAT_1':'Second place... again? Wait. How many civilizations are left?',
'PEACE_1':'A compromise. An outcome in which neither side comes first. We approve.',
'FRIENDLY_1':'Your proposal has reached the second round of consideration. This is a very good sign.',
'NEUTRAL_1':'The Ministry has received your papers. Please take a silver number.',
'HOSTILE_1':'We have nearly exhausted our patience.',
'ATTACKED_1':'You have mistaken patience for surrender. The Ministry will try again.',
'TRADE_1':'An almost perfect agreement. We accept.',
}
TEXT['DAWN'] = '[NEWLINE][NEWLINE]'.join([
'Honorable Acting Chancellor Penultimate, your people await your next attempt at greatness.',
'Throughout history, civilizations have celebrated their greatest victories, their most brilliant discoveries and their most glorious achievements.',
'Your people have experienced something rather different.',
'They have finished second.',
'Again and again, the Ministry has approached greatness, only to watch another nation claim the prize moments before them.',
'Yet your citizens have never surrendered to disappointment.',
'Every defeat became a lesson. Every failure became an opportunity. Every setback inspired another attempt.',
'Now, the Ministry stands ready to challenge the greatest civilizations in history.',
"Build your cities. Educate your citizens. Transform yesterday's failures into tomorrow's achievements.",
'Will your civilization finally claim first place?',
'Or will history remember you as the greatest runner-up of all time?'])
CITIES = ['Runner-Up','Silverhaven','Near Victory','Penultimate','Second Crossing','Almostopolis',
'Honorable Mention','Next Attempt','Narrow Margin','Provisional Bay','Deferred Glory','Another Chance',
'Silver Standard','Rising Again','Final Draft','Better Tomorrow','Second Dawn','The Waiting Room',
'Last Revision','Resilience','Hopeful Assembly','Medalford','The Finalist','Tomorrow First']
for i, name in enumerate(CITIES,1): TEXT[f'CITY_{i}']=name
for i, name in enumerate(['Deputy','Alternate','Reserve','Acting','Interim','Standby','Silver','Almost','Runner','Second'],1): TEXT[f'SPY_{i}']=name
TEXT.update({
 'CIV5_HEADING_1':'The Republic of Second Chances', 'CIV5_TEXT_1':TEXT['CIV_PEDIA'],
 'CIV5_HEADING_2':'Always the Challenger', 'CIV5_TEXT_2':TEXT['TRAIT_HELP'],
 'CIV5_FACTOID_HEADING':'The Silver Standard',
 'CIV5_FACTOID_TEXT':'The Ministry records every near victory so that no useful lesson is lost.',
 'PENULTIMATE_NAME':TEXT['LEADER'], 'PENULTIMATE_SUBTITLE':'The Perpetual Acting Chancellor',
 'PENULTIMATE_LIVED':'Fictional leader; forty-seven years in acting office',
 'PENULTIMATE_TITLES_1':'Acting Chancellor of the Ministry of Almost',
 'PENULTIMATE_HEADING_1':'A Competent Runner-Up', 'PENULTIMATE_TEXT_1':TEXT['LEADER_PEDIA'],
 'PENULTIMATE_FACT_1':'Every winning candidate resigns before taking office.'})

def main():
    def lit(s): return "'"+s.replace("'", "''")+"'"
    sql='-- Generated by tools/generate_text.py.\nINSERT INTO Language_en_US(Tag,Text) VALUES\n'
    sql+=',\n'.join(' ('+lit('TXT_KEY_CWC3_'+key)+','+lit(value)+')' for key,value in TEXT.items())+';\n'
    responses = {
      'RESPONSE_FIRST_GREETING':'GREETING','RESPONSE_DECLAREWAR':'WAR','RESPONSE_DEFEATED':'DEFEAT',
      'RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS':'PEACE','RESPONSE_PEACE_MADE_BY_HUMAN_UNGRACIOUS':'PEACE',
      'RESPONSE_PEACE_OFFER':'PEACE','RESPONSE_GREETING_POLITE_HELLO':'FRIENDLY',
      'RESPONSE_GREETING_NEUTRAL_HELLO':'NEUTRAL','RESPONSE_GREETING_HOSTILE_HELLO':'HOSTILE',
      'RESPONSE_ATTACKED':'ATTACKED','RESPONSE_TRADE_ACCEPT_GENEROUS':'TRADE',
      'RESPONSE_TRADE_ACCEPT_ACCEPTABLE':'TRADE', 'RESPONSE_TRADE_REJECT_UNACCEPTABLE':'NEUTRAL'}
    for response,tag in responses.items():
        sql+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_CWC3_PENULTIMATE','{response}','TXT_KEY_CWC3_{tag}_%',1);\n"
    # Retain a complete text-only fallback for all remaining ordinary diplomacy cases.
    sql+="""INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias)
 SELECT 'LEADER_CWC3_PENULTIMATE',ResponseType,Response,Bias FROM Diplomacy_Responses AS Native
 WHERE Native.LeaderType='LEADER_WASHINGTON' AND NOT EXISTS
 (SELECT 1 FROM Diplomacy_Responses AS Ministry WHERE Ministry.LeaderType='LEADER_CWC3_PENULTIMATE' AND Ministry.ResponseType=Native.ResponseType);
"""
    (ROOT/'TheMinistryOfAlmost/SQL/Ministry_Text.sql').write_text(sql,encoding='utf-8',newline='\n')
    print(f'Generated {len(TEXT)} English localization entries and diplomacy fallbacks')
if __name__=='__main__': main()
