import React from 'react';
import InputErrors from '../../input-errors';

const AdditionalInfoFormSection = (props) => {
  const {
    auction,
    errors,
    isTermAuction,
    updateInformation
  } = props;

  return (
    <section className="auction-info is-gray-1"> {/* Add'l info */}
      <div className="container">
        <div className="content">
          <fieldset>
            <legend className="subtitle is-4" >Additional Information</legend>
            {isTermAuction &&
              <p className="is-italic has-text-gray-3 has-margin-bottom-lg">Specify desired timing of delivery, payment terms, duration of price validity, as well as any other additional delivery terms.</p>
            }
            <div className="field is-horizontal">
              <textarea
                name={'auction[additional_information]'}
                id={'auction_additional_information'}
                className="textarea qa-auction-additional_information"
                defaultValue={auction.additional_information}
                onChange={updateInformation.bind(this, 'auction.additional_information')}>
              </textarea>
              <InputErrors errors={errors.additional_information} />
            </div>
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default AdditionalInfoFormSection;
