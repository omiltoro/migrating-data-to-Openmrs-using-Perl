#!/usr/bin/perl -w


use strict;

use warnings;

use REST::Client;  

use MIME::Base64;  

use JSON;

use Data::Dumper;

use Text::CSV;


#basic connection parameters

my $username = 'username';

my $password = 'password';

my $base64CncodedPass = 'Basic '.encode_base64($username.':'.$password);

my $hostName = 'https://localhost:8443';

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0; #tolerate self signed certs


#OpenMRS globals

#These are unique to each installation.

my $locationUUID = '8d6c993e-c2cc-11de-8d13-0010c6dffd0f';

my $locationName = 'Unknown Location';

my $identifierTypeUUID = '8d79403a-c2cc-11de-8d13-0010c6dffd0f';

my $identifierName = 'Old Identification Number';



#calls

#my $serverType = '/openmrs-standalone'; #OpenMRS standalone install

my $serverType = '/openmrs'; #OpenMRS Enterprise install

my $locationCall = $serverType . '/ws/rest/v1/location';

my $personCall = $serverType . '/ws/rest/v1/person';

my $patientCall = $serverType. '/ws/rest/v1/patient';

my $encounterCall = $serverType. '/ws/rest/v1/encounter';

#prompt for initial or follow-up import


print "Is this an initial import or a follow-up? \n(Y for initial, Any other letter follow-up) \t: ";

my $importChoice = <STDIN>;

chomp($importChoice);

$importChoice = lc($importChoice);


if($importChoice eq 'y')

{

#Call the subroutine to process the initial list

print "Process Initial list...\n";

&processInitialList();

}else{

#call subroutine to process follow-up

print "Processing Follow-up list...\n";

&processFollowUp();

#&lookUpPatient(1004);

}


sub lookUpPatient{

my $patientID = $_[0];

#setup REST client

my $client = REST::Client->new();

$client->setHost( $hostName );

$client->addHeader( 'Authorization', $base64CncodedPass);

$client->addHeader( 'Content-Type' => 'application/json');

my $getString = "?q=$patientID";


#print Dumper($client->GET($patientCall.$getString)); #for debug

$client->GET($patientCall.$getString);


#This contains the references to hashes of the results of the JSON call.

my $decodedJson = decode_json( $client->responseContent() ); 

my @arrayOfHashes = @{$decodedJson->{'results'}}; #only works on get calls

my $uniqueID = $arrayOfHashes[0]->{'uuid'};	

#status msg for debug purposes

print "Patient UUID for the PERSON with Patient ID $patientID is $uniqueID . \n";

return $uniqueID;

}


sub processFollowUp{

#Grab data from CSV file

my $file = "Test1.csv";

open my $fh, "<", $file or die "$file: $!";

my $csv = Text::CSV->new ({

binary    => 1, # Allow special character. Always set this

auto_diag => 1, # Report irregularities immediately

});

#Iterate over each row and process it.

while(my $row = $csv->getline ($fh)){

print "@$row\n";

print "Patient ID: $row->[0]\nLastName: $row->[1]\n";

my $patientID = $row->[0];

my $patientLastName = $row->[1];

my $patientFirstName = $row->[2];

my $patientDateOfBirth = $row->[3];

my $assessmentDate = $row->[4];

my $patientAge = $row->[5];

my $primaryProvider = $row->[6];

my $patientHeightFeet = $row->[7];

my $patientHeightInches = $row->[8];

my $patientWeightLbs = $row->[9];

my $patientBMI= $row->[10];

my $patientSystolicBP = $row->[11];

my $patientDiastolicBP = $row->[12];

my $patientBpMonitor = $row->[13];

my $smokingStatus = $row->[14];

my $patientLabDate = $row->[15];

my $patientHBA1c = $row->[16];

my $patientBloodGlucose = $row->[17];

my $patientBloodGlucoseMeter = $row->[18];

my $patientTotalCholesterol = $row->[19];

my $patientHDL = $row->[20];

my $patientLDL = $row->[21];

my $patientTriGlycerides = $row->[22];

my $patientMicroalbumin = $row->[23];

my $patientGFR = $row->[24];

#convert some imperial values to metric

my $patientWeightKG = 0.453*$patientWeightLbs; #convert from Lbs to Kg

my $patientHeightCM = (($patientHeightFeet*12)+($patientHeightInches))*2.54; #convert height in inches to CM

#change the / character to - to work in post operations as needed

$patientDateOfBirth =~ s/\//-/g;

my $patientUUID = &lookUpPatient($patientID);

#then create the encounter for the patient.

my $encounterType = "Follow-up Visit";

my $providerUUID = '491f95cc-23e6-46a3-adfb-1c70ab4d2ae9';

my $encounterStatus = &createEncounter(

$patientUUID, $patientWeightKG, $assessmentDate, $encounterType, $providerUUID, $locationName, $patientHeightCM,

$patientSystolicBP, $patientDiastolicBP, $smokingStatus, $patientLabDate, $patientHBA1c, $patientBloodGlucose, 

$patientBloodGlucoseMeter, $patientTotalCholesterol, $patientHDL, $patientLDL, $patientTriGlycerides, $patientMicroalbumin,

$patientGFR, $patientBpMonitor, $patientBMI

);

print "Status for $patientFirstName $patientLastName is $encounterStatus.\n";

<>;

}

close $fh;


}


#function to process the initial list

sub processInitialList{


#Grab data from CSV file

my $file = "export.csv";

open my $fh, "<", $file or die "$file: $!";

my $csv = Text::CSV->new ({

binary    => 1, # Allow special character. Always set this

auto_diag => 1, # Report irregularities immediately

});

#Iterate over each row and process it.

while(my $row = $csv->getline ($fh)){

#print "@$row\n";

#print "Patient ID: $row->[0]\nLastName: $row->[1]\n";

my $patientID = $row->[0];

my $patientLastName = $row->[1];

my $patientFirstName = $row->[2];

my $patientDateOfBirth = $row->[3];

my $assessmentDate = $row->[4];

my $patientAge = $row->[5];

my $primaryProvider = $row->[6];

my $patientHeightFeet = $row->[7];

my $patientHeightInches = $row->[8];

my $patientWeightLbs = $row->[9];

my $patientBMI= $row->[10];

my $patientSystolicBP = $row->[11];

my $patientDiastolicBP = $row->[12];

my $patientBpMonitor = $row->[13];

my $smokingStatus = $row->[14];

my $patientLabDate = $row->[15];

my $patientHBA1c = $row->[16];

my $patientBloodGlucose = $row->[17];

my $patientBloodGlucoseMeter = $row->[18];

my $patientTotalCholesterol = $row->[19];

my $patientHDL = $row->[20];

my $patientLDL = $row->[21];

my $patientTriGlycerides = $row->[22];

my $patientMicroalbumin = $row->[23];

my $patientGFR = $row->[24];

#convert some imperial values to metric

my $patientWeightKG = 0.453*$patientWeightLbs; #convert from Lbs to Kg

my $patientHeightCM = (($patientHeightFeet*12)+($patientHeightInches))*2.54; #convert height in inches to CM

#change the / character to - to work in post operations as needed

$patientDateOfBirth =~ s/\//-/g;

print "Enter the sex of ".$patientFirstName." ".$patientLastName."(M or F): ";

my $patientGender = <STDIN>;

chomp($patientGender);

#createPerson(@$row);

#create the patient, returning UUID

#add code to look up patient first and skip if they exist

#http://localhost:8081/openmrs-standalone/ws/rest/v1/patient?q=22223 lookup format

my $patientUUID = &createPerson($patientFirstName, $patientLastName, $patientGender, $patientDateOfBirth, $patientID);

print "Created patient $patientFirstName $patientLastName with the ID: $patientUUID.\n\n";

#then create the encounter for the patient.

my $encounterType = "Follow-up Visit";

my $providerUUID = 'bea93a7d-6748-4422-b464-3d47fc991bab';

my $encounterStatus = &createEncounter(

$patientUUID, $patientWeightKG, $assessmentDate, $encounterType, $providerUUID, $locationName, $patientHeightCM,

$patientSystolicBP, $patientDiastolicBP, $smokingStatus, $patientLabDate, $patientHBA1c, $patientBloodGlucose, 

$patientBloodGlucoseMeter, $patientTotalCholesterol, $patientHDL, $patientLDL, $patientTriGlycerides, $patientMicroalbumin,

$patientGFR, $patientBpMonitor, $patientBMI

);

print "Creation status for $patientFirstName $patientLastName is $encounterStatus.\n\n";

}

close $fh;


}


#call function to create PERSON

#returns UUID of created PATIENT

sub createPerson{

my $personFirstName = $_[0];

my $personLastName = $_[1];

my $personGender = $_[2];

my $personDOB = $_[3];

my $patientID = $_[4];


#set the post values for a new person

my %postPersonBodyContent = ( birthdate => $personDOB, gender => $personGender, names => [{ givenName => $personFirstName, familyName => $personLastName}]);

my $dataToPost = encode_json(\%postPersonBodyContent);

#setup REST client

my $client = REST::Client->new();

$client->setHost( $hostName );

$client->addHeader( 'Authorization', $base64CncodedPass);

$client->addHeader( 'Content-Type' => 'application/json');


#print "About to POST: ". $dataToPost."\n";

#print Dumper($client->POST($personCall, $dataToPost)); #for debug

$client->POST($personCall, $dataToPost);


#This contains the references to hashes of the results of the JSON call.

my $decodedJson = decode_json( $client->responseContent() ); 


#my @arrayOfHashes = @{$decodedJson->{'results'}}; #only works on get calls

my @arrayOfHashes = $decodedJson;


#How many results came back from the call

#my $numberOfElements = scalar(@arrayOfHashes);

#print "\nI got ". $numberOfElements . " elements back from the call.\n";

#print "The hash details: \n";

#print Dumper($arrayOfHashes[0]);


my $uniqueID = $arrayOfHashes[0]->{'uuid'};	

#status msg

#print "Unique ID for the created PERSON is ". $uniqueID . "\n";

#create a patient from the person ID provided.

my $patientReturnStatus = &createPatient($uniqueID, $patientID);


#print "Unique ID for the created PATIENT is ". $patientReturnStatus . " \n";

#UUID for person and patient are the same.

return $patientReturnStatus;

}


#call function to create PATIENT

#returns UUID of created PATIENT

sub createPatient{


my $uuidPerson = $_[0]; #grab UUID from person creation

#my $uuidPerson = 'TEST UUID GOES HERE'; #for testing/debug

my $assignedID = $_[1]; #increment ID by one.

my %postPatientContent = ( person => $uuidPerson , identifiers => [{identifier => "$assignedID", location => $locationUUID, 

preferred => "true", identifierType => $identifierTypeUUID }], );

my $postData = "\{\"person\":\"".$uuidPerson."\",\"identifiers\":\[\{\"identifier\":\"".$assignedID."\", 

\"location\":\"".$locationUUID."\", \"preferred\":\""."true"."\", \"identifierType\":\"".$identifierTypeUUID."\"}\]\}";

my $dataToPost = encode_json(\%postPatientContent);

#print "About to POST: ". $dataToPost."\n";

# Set up the connection  

my $client = REST::Client->new();

$client->setHost( $hostName );

$client->addHeader( 'Authorization', $base64CncodedPass);

$client->addHeader( 'Content-Type' => 'application/json');


#execute post of person data to create patient

#print Dumper($client->POST($patientCall, $dataToPost)); #for debug

$client->POST($patientCall, $dataToPost);

#print Dumper($client->responseContent());


#This contains the references to hashes of the results of the JSON call.

my $decodedPatientJson = decode_json( $client->responseContent() ); 


#my @arrayOfHashes = @{$decodedJson->{'results'}}; #only works on get calls

my @arrayOfHashesPatientResponse = $decodedPatientJson;

#print Dumper(@arrayOfHashesPatientResponse);


my $createdPatientID = $arrayOfHashesPatientResponse[0]->{'uuid'};

#print "Created patient with ID: " . $createdPatientID . " \n";

return $createdPatientID;

}


sub createEncounter{

#The concept IDs from OpenMRS

    #move these to a property file to bre read-in at runtime?

my $weightConceptID = "5089AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $heightConceptID = "5090AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $systolicConceptID = "5085AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $diastolicConceptID = "5086AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $bpMonitorConceptID = "8c6d0b16-6763-4128-928d-d741daad6a92"; #custom

my $smokingStatusConceptID = "94f2a4dc-484f-456f-abbd-e247fb1fe679"; #custom

my $labDateConceptID = "bd259103-3b7d-42de-b498-dbf3992ef9d2"; #custom

my $HBA1CConceptID = "159644AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $bloodGlucoseConceptID = "887AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $bloodGlucoseMeterConceptID = "acaa9ff8-f15b-4390-9fc7-969205128055"; #custom

my $totalCholesterolConceptID = "1006AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $HDLConceptID = "1007AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $LDLConceptID = "1008AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $triGlyceridesConceptID = "1009AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $microAlbuminConceptID = "848AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $GFRConceptID = "161132AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

my $bodyMassIndex = "1342AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

#Iterate over each function argument and check if it is defined. If not, set to zero.

foreach(@_)

{

if($_ eq '')

{

$_ = 0;

#print "Set a value to zero\n";

}

}

my $uuidPerson = $_[0]; #grab UUID from person creation

my $patientWeight = $_[1]; #increment ID by one.

my $encounterDateTime = $_[2];

my $encounterType = $_[3];

my $encounterProviderUUID = $_[4];

my $encounterLocation = $_[5];

my $patientHeightCM = $_[6];

my $patientSystolicBP = $_[7];

my $patientDiastolicBP = $_[8];

my $patientsmokingStatus = $_[9];

my $patientLabDate = $_[10];

my $patientHBA1 = $_[11];

my $patientBloodGlucose = $_[12];

my $patientBloodGlucoseMeter = $_[13];

my $patienttotalCholesterol = $_[14];

my $patientHDL = $_[15];

my $patientLDL = $_[16];

my $patientTriglycerides = $_[17];

my $patientMicroalbumin = $_[18];

my $patientGFR = $_[19];

my $patientBPMonitor = $_[20];

my $patientBMI = $_[21];

my $postData = "\{\"patient\":\"".$uuidPerson."\",\"encounterDatetime\":\"".$encounterDateTime."\",

\"encounterType\":\"".$encounterType."\",\"location\":\"".$encounterLocation."\",

\"obs\":\

[\{\"concept\":\"".$weightConceptID."\", \"value\":\"".$patientWeight."\"},

\{\"concept\":\"".$heightConceptID."\", \"value\":\"".$patientHeightCM."\"},

\{\"concept\":\"".$systolicConceptID."\", \"value\":\"".$patientSystolicBP."\"},

\{\"concept\":\"".$diastolicConceptID."\", \"value\":\"".$patientDiastolicBP."\"},

\{\"concept\":\"".$smokingStatusConceptID."\", \"value\":\"".$patientsmokingStatus."\"},

\{\"concept\":\"".$labDateConceptID."\", \"value\":\"".$patientLabDate."\"},

\{\"concept\":\"".$HBA1CConceptID."\", \"value\":\"".$patientHBA1."\"},

\{\"concept\":\"".$bloodGlucoseConceptID."\", \"value\":\"".$patientBloodGlucose."\"},

\{\"concept\":\"".$bloodGlucoseMeterConceptID."\", \"value\":\"".$patientBloodGlucoseMeter."\"},

\{\"concept\":\"".$totalCholesterolConceptID."\", \"value\":\"".$patienttotalCholesterol."\"},

\{\"concept\":\"".$HDLConceptID."\", \"value\":\"".$patientHDL."\"},

\{\"concept\":\"".$LDLConceptID."\", \"value\":\"".$patientLDL."\"},

\{\"concept\":\"".$triGlyceridesConceptID."\", \"value\":\"".$patientTriglycerides."\"},

\{\"concept\":\"".$microAlbuminConceptID."\", \"value\":\"".$patientMicroalbumin."\"},

\{\"concept\":\"".$GFRConceptID."\", \"value\":\"".$patientGFR."\"},

\{\"concept\":\"".$bodyMassIndex."\", \"value\":\"".$patientBMI."\"},

\{\"concept\":\"".$bpMonitorConceptID."\", \"value\":\"".$patientBPMonitor."\"} \]

\}";

#COMMENT OUT LATER

print "The data to be posted is: Dumper($postData) \n";

# Set up the connection  

my $client = REST::Client->new();

$client->setHost( $hostName );

$client->addHeader( 'Authorization', $base64CncodedPass);

$client->addHeader( 'Content-Type' => 'application/json');


#execute post of person data to create patient

#print Dumper($client->POST($encounterCall, $postData)); #for debug

#UNCOMMENT FOR PROD

$client->POST($encounterCall, $postData);

my $resCode = $client->responseCode();

print "Create encounter response code is $resCode \n\n";

#print Dumper($client->responseContent()); view server response from encounter creation


#This contains the references to hashes of the results of the JSON call.

my @arrayOfHashesResponse = decode_json( $client->responseContent() ); 


#my @arrayOfHashes = @{$decodedJson->{'results'}}; #only works on get calls

#print Dumper(@arrayOfHashesPatientResponse);


my $createdEncounter = $arrayOfHashesResponse[0]->{'uuid'};

#print "Created patient with ID: " . $createdPatientID . " \n";

#<STDIN>;

return $createdEncounter;

}

###
