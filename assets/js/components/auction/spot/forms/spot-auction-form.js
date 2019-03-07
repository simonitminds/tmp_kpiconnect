import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import InputField from '../../../input-field';
import CheckBoxField from '../../../check-box-field';
import DateInput from '../../../date-input';
import TimeInput from '../../../time-input';
import { portLocalTime } from '../../../../utilities';
import SupplierList  from '../../common/forms/supplier-list';
import VesselFuelForm from './vessel-fuel-form';
import PortSelectFormSection from '../../common/forms/port-select-form-section';
import AdditionalInfoFormSection from '../../common/forms/additional-info-form-section';
import AuctionDetailsFormSection from '../../common/forms/auction-details-form-section';

const SpotAuctionForm = (props) => {
  const {
    auction,
    errors,
    type,
    deselectAllSuppliers,
    credit_margin_amount,
    eta_date,
    eta_time,
    etd_date,
    etd_time,
    fuels,
    ports,
    scheduled_start_date,
    scheduled_start_time,
    selectAllSuppliers,
    selectPort,
    selectAuctionType,
    selectedSuppliers,
    suppliers,
    toggleSupplier,
    updateDate,
    updateMonth,
    updateInformation,
    updateInformationFromCheckbox,
    vessels,
  } = props;

  const port_id = auction.port_id ? auction.port_id : "";
  const selectedPort = _.chain(ports)
        .filter(['id', auction.port_id])
        .first()
        .value();

  return (
    <React.Fragment>
      <PortSelectFormSection auction={auction}
                             errors={errors}
                             port_id={port_id}
                             ports={ports}
                             selectPort={selectPort}
                             updateMonth={updateMonth}
                             updateInformation={updateInformation}
                             hasDurationAndTerminal={false} />

      <SupplierList onDeSelectAllSuppliers={deselectAllSuppliers}
                    onSelectAllSuppliers={selectAllSuppliers}
                    onToggleSupplier={toggleSupplier}
                    selectedPort={selectedPort}
                    selectedSuppliers={selectedSuppliers}
                    suppliers={suppliers}
                    errors={errors} />

     <VesselFuelForm auction={auction}
                     errors={errors}
                     vessels={vessels}
                     fuels={fuels}
                     vesselFuels={auction.vessel_fuels}
                     portId={port_id}
                     ports={ports} />

      <AdditionalInfoFormSection auction={auction} errors={errors} updateInformation={updateInformation} isTermAuction={false}/>

      <AuctionDetailsFormSection auction={auction}
                                 errors={errors}
                                 credit_margin_amount={credit_margin_amount}
                                 isTermAuction={false}
                                 updateInformation={updateInformation}
                                 updateInformationFromCheckbox={updateInformationFromCheckbox}
                                 updateDate={updateDate} />

    </React.Fragment>
  );
};

export default SpotAuctionForm;
