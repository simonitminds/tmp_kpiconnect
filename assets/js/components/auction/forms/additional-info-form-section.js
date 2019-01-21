import React from 'react';

const AdditionalInfoFormSection = (props) => {
  const {
    auction,
    updateInformation
  } = props;

  return (
    <section className="auction-info is-gray-1"> {/* Add'l info */}
      <div className="container">
        <div className="content">
          <fieldset>
            <legend className="subtitle is-4" >Additional Information</legend>
            <div className="field is-horizontal">
              <textarea
                name={'auction[additional_information]'}
                id={'auction_additional_information'}
                className="textarea qa-auction-additional_information"
                defaultValue={auction.additional_information}
                onChange={updateInformation.bind(this, 'auction.additional_information')}>
              </textarea>
            </div>
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default AdditionalInfoFormSection;
